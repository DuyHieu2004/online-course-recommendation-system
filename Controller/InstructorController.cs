using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using online_course_recommendation_system.Service;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "GiaoVien,Admin")]
    public class InstructorController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _env;
        private readonly ICloudinaryService _cloudinaryService;

        public InstructorController(AppDbContext context, IWebHostEnvironment env, ICloudinaryService cloudinaryService)
        {
            _context = context;
            _env = env;
            _cloudinaryService = cloudinaryService;
        }

        // ① GET /api/instructor/courses — Khóa học của giảng viên
        [HttpGet("courses")]
        public async Task<IActionResult> GetMyCourses()
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var courses = await _context.GiangVienKhoaHocs
                .Where(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHocNavigation.IsDeleted == false)
                .Include(gv => gv.MaKhoaHocNavigation)
                    .ThenInclude(k => k.MaTheLoaiNavigation)
                .Include(gv => gv.MaKhoaHocNavigation)
                    .ThenInclude(k => k.TienDos)
                .Include(gv => gv.MaKhoaHocNavigation)
                    .ThenInclude(k => k.DanhGia)
                .Select(gv => new
                {
                    gv.MaKhoaHocNavigation.MaKhoaHoc,
                    gv.MaKhoaHocNavigation.TieuDe,
                    gv.MaKhoaHocNavigation.TinhTrang,
                    gv.MaKhoaHocNavigation.GiaGoc,
                    gv.MaKhoaHocNavigation.TbdanhGia,
                    gv.MaKhoaHocNavigation.AnhUrl,
                    gv.MaKhoaHocNavigation.NgayTao,
                    TheLoai = gv.MaKhoaHocNavigation.MaTheLoaiNavigation != null
                        ? gv.MaKhoaHocNavigation.MaTheLoaiNavigation.Ten : null,
                    SoHocVien = gv.MaKhoaHocNavigation.TienDos.Count,
                    SoLuongDanhGia = gv.MaKhoaHocNavigation.DanhGia.Count,
                    gv.LaGiangVienChinh,
                    // Thêm tính toán Sentiment Stats
                    sentimentStats = new 
                    {
                        // Nhóm Tích cực
                        pos = gv.MaKhoaHocNavigation.DanhGia.Count(d => 
                            d.Emotion == "Enjoyment" || d.Emotion == "Surprise"),
                        
                        // Nhóm Tiêu cực
                        neg = gv.MaKhoaHocNavigation.DanhGia.Count(d => 
                            d.Emotion == "Sadness" || d.Emotion == "Anger" || 
                            d.Emotion == "Disgust" || d.Emotion == "Fear"),
                        
                        // Nhóm Trung tính
                        neu = gv.MaKhoaHocNavigation.DanhGia.Count(d => 
                            d.Emotion == "Other" || string.IsNullOrEmpty(d.Emotion)),
                        
                        // Phần trăm tích cực
                        percentPos = gv.MaKhoaHocNavigation.DanhGia.Count() > 0 
                            ? Math.Round((double)gv.MaKhoaHocNavigation.DanhGia.Count(d => d.Emotion == "Enjoyment" || d.Emotion == "Surprise") 
                            / gv.MaKhoaHocNavigation.DanhGia.Count() * 100, 1) 
                            : 0
                    }
                })
                .ToListAsync();

            return Ok(courses);
        }

        [HttpGet("courses/{courseId}/sentiment-details")]
        public async Task<IActionResult> GetCourseSentimentDetails(int courseId)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == courseId);
            if (!isOwner) return Forbid();

            var comments = await _context.DanhGia
                .Where(d => d.MaKhoaHoc == courseId && !string.IsNullOrEmpty(d.BinhLuan))
                .OrderByDescending(d => d.NgayDanhGia)
                .Select(d => new
                {
                    text = d.BinhLuan,
                    rating = d.Rating,
                    emotion = d.Emotion ?? "Other"
                })
                .ToListAsync();

            return Ok(comments);
        }

        // ② GET /api/instructor/students — Danh sách học viên
        [HttpGet("students")]
        public async Task<IActionResult> GetStudents(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            // Lấy tất cả khóa học mà giảng viên dạy
            var courseIds = await _context.GiangVienKhoaHocs
                .Where(gv => gv.MaGiangVien == userId.Value)
                .Select(gv => gv.MaKhoaHoc)
                .ToListAsync();

            var query = _context.TienDos
                .Where(t => t.MaKhoaHoc.HasValue && courseIds.Contains(t.MaKhoaHoc.Value))
                .Include(t => t.MaNguoiDungNavigation)
                .Include(t => t.MaKhoaHocNavigation);

            var totalCount = await query.CountAsync();

            var students = await query
                .OrderByDescending(t => t.NgayThamGia)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(t => new
                {
                    HocVien = t.MaNguoiDungNavigation == null ? null : new
                    {
                        t.MaNguoiDungNavigation.MaNguoiDung,
                        t.MaNguoiDungNavigation.Ten,
                        t.MaNguoiDungNavigation.Email,
                        t.MaNguoiDungNavigation.LinkAnhDaiDien
                    },
                    KhoaHoc = t.MaKhoaHocNavigation == null ? null : new
                    {
                        t.MaKhoaHocNavigation.MaKhoaHoc,
                        t.MaKhoaHocNavigation.TieuDe
                    },
                    t.PhanTramTienDo,
                    TinhTrang = t.TinhTrang == true ? "Đang học" : "Chưa bắt đầu",
                    t.NgayThamGia,
                    t.NgayKetThuc
                })
                .ToListAsync();

            return Ok(new { totalCount, page, pageSize, data = students });
        }

        // ③ GET /api/instructor/stats — Thống kê tổng quan
        [HttpGet("stats")]
        public async Task<IActionResult> GetStats([FromQuery] string range = "30 ngày qua", [FromQuery] int? courseId = null)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized(new { message = "Token không hợp lệ." });

            var courseIdsQuery = _context.GiangVienKhoaHocs.Where(gv => gv.MaGiangVien == userId.Value);
            if (courseId.HasValue && courseId.Value > 0)
                courseIdsQuery = courseIdsQuery.Where(gv => gv.MaKhoaHoc == courseId.Value);

            var courseIds = await courseIdsQuery.Select(gv => gv.MaKhoaHoc).ToListAsync();

            if (!courseIds.Any()) 
                return Ok(new { tongKhoaHoc = 0, tongHocVien = 0, tbDanhGia = 0, tongDoanhThu = 0, tongDanhGia = 0 });

            DateTime? startDate = range switch
            {
                "7 ngày qua" => DateTime.Now.AddDays(-7),
                "30 ngày qua" => DateTime.Now.AddDays(-30),
                "90 ngày qua" => DateTime.Now.AddDays(-90),
                "Năm nay" => new DateTime(DateTime.Now.Year, 1, 1),
                _ => null
            };

            var tongKhoaHoc = courseIds.Count;

            var tongHocVienQuery = _context.TienDos.Where(t => t.MaKhoaHoc.HasValue && courseIds.Contains(t.MaKhoaHoc.Value));
            if (startDate.HasValue) tongHocVienQuery = tongHocVienQuery.Where(t => t.NgayThamGia >= startDate.Value);
            var tongHocVien = await tongHocVienQuery.Select(t => t.MaNguoiDung).Distinct().CountAsync();

            var danhGiaQuery = _context.DanhGia.Where(d => d.MaKhoaHoc.HasValue && courseIds.Contains(d.MaKhoaHoc.Value) && d.Rating.HasValue);
            var allDanhGia = await danhGiaQuery.ToListAsync();
            var latestDanhGia = allDanhGia.GroupBy(d => new { d.MaKhoaHoc, d.MaNguoiDung })
                .Select(g => g.OrderByDescending(x => x.NgayDanhGia).FirstOrDefault()).Where(d => d != null).ToList();

            var filteredDanhGia = startDate.HasValue ? latestDanhGia.Where(d => d.NgayDanhGia.HasValue && d.NgayDanhGia.Value >= startDate.Value).ToList() : latestDanhGia;
            var tbDanhGia = filteredDanhGia.Any() ? filteredDanhGia.Average(d => d.Rating.Value) : 0;
            var tongDanhGia = filteredDanhGia.Count;

            var doanhThuQuery = _context.ChiTietHoaDons.Include(ct => ct.MaHoaDonNavigation)
                .Where(ct => ct.MaKhoaHoc.HasValue && courseIds.Contains(ct.MaKhoaHoc.Value) && ct.MaHoaDonNavigation != null && ct.MaHoaDonNavigation.TinhTrangThanhToan == true);
            if (startDate.HasValue) doanhThuQuery = doanhThuQuery.Where(ct => ct.MaHoaDonNavigation.NgayTao >= startDate.Value);

            var tongDoanhThuRaw = await doanhThuQuery.SumAsync(ct => ct.Gia) ?? 0;
            var tongDoanhThu = tongDoanhThuRaw * 0.7m;

            return Ok(new { tongKhoaHoc, tongHocVien, tbDanhGia = Math.Round(tbDanhGia, 1), tongDoanhThu, tongDanhGia });
        }

        // Thay thế API GetRevenueSeries cũ để hỗ trợ lọc theo khóa học
        [HttpGet("stats/revenue-series")]
        public async Task<IActionResult> GetRevenueSeries([FromQuery] string range = "30 ngày qua", [FromQuery] int? courseId = null)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var courseIdsQuery = _context.GiangVienKhoaHocs.Where(gv => gv.MaGiangVien == userId.Value);
            if (courseId.HasValue && courseId.Value > 0)
                courseIdsQuery = courseIdsQuery.Where(gv => gv.MaKhoaHoc == courseId.Value);

            var courseIds = await courseIdsQuery.Select(gv => gv.MaKhoaHoc).ToListAsync();
            if (!courseIds.Any()) return Ok(new[] { new { Month = "Hiện tại", Revenue = 0 } });

            var query = _context.ChiTietHoaDons.Include(ct => ct.MaHoaDonNavigation)
                .Where(ct => ct.MaKhoaHoc.HasValue && courseIds.Contains(ct.MaKhoaHoc.Value) && ct.MaHoaDonNavigation != null && ct.MaHoaDonNavigation.TinhTrangThanhToan == true);

            var now = DateTime.Now;
            DateTime? startDate = range switch {
                "7 ngày qua" => now.AddDays(-7), "30 ngày qua" => now.AddDays(-30),
                "90 ngày qua" => now.AddDays(-90), "Năm nay" => new DateTime(now.Year, 1, 1), _ => null
            };

            if (startDate.HasValue) query = query.Where(ct => ct.MaHoaDonNavigation.NgayTao >= startDate.Value);

            var rawData = await query.Select(ct => new {
                NgayTao = ct.MaHoaDonNavigation.NgayTao.Value,
                DoanhThuThuc = (ct.Gia ?? 0) * 0.7m
            }).ToListAsync();

            object result;
            if (range == "7 ngày qua") {
                var list = new List<object>();
                for (int i = 6; i >= 0; i--) { var date = now.Date.AddDays(-i); list.Add(new { Month = date.ToString("dd/MM"), Revenue = rawData.Where(x => x.NgayTao.Date == date).Sum(x => x.DoanhThuThuc) }); }
                result = list;
            } else if (range == "30 ngày qua") {
                var list = new List<object>();
                for (int i = 4; i >= 1; i--) { var start = now.AddDays(-i * 7.5); var end = now.AddDays(-(i - 1) * 7.5); list.Add(new { Month = $"Tuần {5 - i}", Revenue = rawData.Where(x => x.NgayTao >= start && x.NgayTao < end).Sum(x => x.DoanhThuThuc) }); }
                result = list;
            } else if (range == "90 ngày qua") {
                var list = new List<object>();
                for (int i = 2; i >= 0; i--) { var m = now.AddMonths(-i); list.Add(new { Month = $"Tháng {m.Month}", Revenue = rawData.Where(x => x.NgayTao.Month == m.Month && x.NgayTao.Year == m.Year).Sum(x => x.DoanhThuThuc) }); }
                result = list;
            } else if (range == "Năm nay") {
                var list = new List<object>();
                for (int i = 1; i <= 12; i++) { list.Add(new { Month = $"T{i}", Revenue = rawData.Where(x => x.NgayTao.Month == i && x.NgayTao.Year == now.Year).Sum(x => x.DoanhThuThuc) }); }
                result = list;
            } else {
                if (!rawData.Any()) result = new[] { new { Month = now.Year.ToString(), Revenue = 0 } };
                else {
                    var list = new List<object>(); int minYear = rawData.Min(x => x.NgayTao.Year);
                    for (int y = minYear; y <= now.Year; y++) { list.Add(new { Month = y.ToString(), Revenue = rawData.Where(x => x.NgayTao.Year == y).Sum(x => x.DoanhThuThuc) }); }
                    result = list;
                }
            }
            return Ok(result);
        }

        // THÊM MỚI TOÀN BỘ: API lấy danh sách giao dịch thanh toán chi tiết
        [HttpGet("transactions")]
        public async Task<IActionResult> GetTransactions([FromQuery] string range = "30 ngày qua", [FromQuery] int? courseId = null)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var courseIdsQuery = _context.GiangVienKhoaHocs.Where(gv => gv.MaGiangVien == userId.Value);
            if (courseId.HasValue && courseId.Value > 0)
                courseIdsQuery = courseIdsQuery.Where(gv => gv.MaKhoaHoc == courseId.Value);

            var courseIds = await courseIdsQuery.Select(gv => gv.MaKhoaHoc).ToListAsync();

            var query = _context.ChiTietHoaDons
                .Include(ct => ct.MaHoaDonNavigation).ThenInclude(hd => hd.MaNguoiDungNavigation)
                .Include(ct => ct.MaKhoaHocNavigation)
                .Where(ct => ct.MaKhoaHoc.HasValue && courseIds.Contains(ct.MaKhoaHoc.Value) &&
                             ct.MaHoaDonNavigation != null && ct.MaHoaDonNavigation.TinhTrangThanhToan == true);

            var now = DateTime.Now;
            DateTime? startDate = range switch {
                "7 ngày qua" => now.AddDays(-7), "30 ngày qua" => now.AddDays(-30),
                "90 ngày qua" => now.AddDays(-90), "Năm nay" => new DateTime(now.Year, 1, 1), _ => null
            };
            if (startDate.HasValue) query = query.Where(ct => ct.MaHoaDonNavigation.NgayTao >= startDate.Value);

            var transactions = await query
                .OrderByDescending(ct => ct.MaHoaDonNavigation.NgayTao)
                .Select(ct => new {
                    MaGiaoDich = ct.MaHoaDonNavigation.MaHoaDon,
                    NgayTao = ct.MaHoaDonNavigation.NgayTao,
                    KhoaHoc = ct.MaKhoaHocNavigation.TieuDe,
                    NguoiMua = ct.MaHoaDonNavigation.MaNguoiDungNavigation.Ten,
                    GiaGop = ct.Gia ?? 0,
                    PhiNenTang = (ct.Gia ?? 0) * 0.3m,
                    ThucNhan = (ct.Gia ?? 0) * 0.7m
                }).ToListAsync();

            return Ok(transactions);
        }

        // ④ POST /api/instructor/courses — Tạo khóa học mới
        [HttpPost("courses")]
        public async Task<IActionResult> CreateCourse([FromBody] CreateCourseRequest request)
        {
            try
            {
                var userId = GetUserIdFromToken();
                if (userId == null)
                    return Unauthorized(new { message = "Token không hợp lệ." });

                var course = new KhoaHoc
                {
                    TieuDe = request.TieuDe,
                    TieuDePhu = request.TieuDePhu,
                    MoTa = request.MoTa,
                    GiaGoc = request.GiaGoc,
                    MaTheLoai = request.MaTheLoai,
                    KiNang = request.KiNang,
                    NgayTao = DateTime.Now,
                    NgayCapNhat = DateTime.Now,
                    TinhTrang = "Draft", // Mặc định là Nháp
                    TbdanhGia = 0
                };

                _context.KhoaHocs.Add(course);
                await _context.SaveChangesAsync();

                // Liên kết giáo viên với khóa học
                _context.GiangVienKhoaHocs.Add(new GiangVienKhoaHoc
                {
                    MaGiangVien = userId.Value,
                    MaKhoaHoc = course.MaKhoaHoc,
                    LaGiangVienChinh = true
                });
                await _context.SaveChangesAsync();

                return Ok(new { message = "Tạo khóa học thành công.", courseId = course.MaKhoaHoc });
            }
            catch (Exception ex)
            {
                var innerMessage = ex.InnerException != null ? ex.InnerException.Message : "";
                return StatusCode(500, new { message = $"Error: {ex.Message}. Inner: {innerMessage}" });
            }
        }

        // ⑤ PUT /api/instructor/courses/{id} — Cập nhật thông tin khóa học
        [HttpPut("courses/{id}")]
        public async Task<IActionResult> UpdateCourse(int id, [FromBody] UpdateCourseRequest request)
        {
            try
            {
                var userId = GetUserIdFromToken();
                if (userId == null)
                    return Unauthorized(new { message = "Token không hợp lệ." });

                // Kiểm tra xem giáo viên có quyền sở hữu khóa học hay không
                var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == id);
                if (!isOwner) return Forbid();

                var course = await _context.KhoaHocs.FindAsync(id);
                if (course == null) return NotFound(new { message = "Không tìm thấy khóa học." });

            course.TieuDe = request.TieuDe;
            course.TieuDePhu = request.TieuDePhu;
            course.MoTa = request.MoTa;
            course.GiaGoc = request.GiaGoc;
            course.MaTheLoai = request.MaTheLoai;
            course.KiNang = request.KiNang;
            course.ThoiGianHocDuKien = request.ThoiGianHocDuKien;
            course.ThoiGianChoPhepTre = request.ThoiGianChoPhepTre;
            if (!string.IsNullOrEmpty(request.TinhTrang))
            {
                // Chỉ cho phép admin hoặc logic khác ngoài instructor controller này (hoặc nếu ta muốn cho phép ở đây)
                // Tuy nhiên ta nên giới hạn instructor chỉ được set sang Draft hoặc Pending
                if (request.TinhTrang == "Draft" || request.TinhTrang == "Pending")
                {
                    course.TinhTrang = request.TinhTrang;
                }
            }
            course.NgayCapNhat = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật khóa học thành công." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Error: {ex.Message}" });
            }
        }

        // ⑤.1 POST /api/instructor/courses/{id}/submit — Gửi khóa học duyệt
        [HttpPost("courses/{id}/submit")]
        public async Task<IActionResult> SubmitCourse(int id)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == id);
            if (!isOwner) return Forbid();

            var course = await _context.KhoaHocs
                .Include(k => k.Chuongs).ThenInclude(c => c.BaiHocs)
                .FirstOrDefaultAsync(k => k.MaKhoaHoc == id);

            if (course == null) return NotFound(new { message = "Không tìm thấy khóa học để gửi duyệt." });

            if (course.TinhTrang != "Draft" && course.TinhTrang != "Rejected")
            {
                return BadRequest(new { message = "Chỉ có thể gửi duyệt khóa học đang ở trạng thái Nháp hoặc Bị từ chối." });
            }

            // Kiểm tra tối thiểu 1 chương và 1 bài học
            bool hasContent = course.Chuongs != null && course.Chuongs.Any() && course.Chuongs.Any(c => c.BaiHocs != null && c.BaiHocs.Any());
            
            if (!hasContent)
            {
                return BadRequest(new { message = "Khóa học phải có ít nhất một chương và một bài học trước khi gửi duyệt. Vui lòng thêm nội dung cho khóa học của bạn." });
            }

            course.TinhTrang = "Pending";
            course.NgayCapNhat = DateTime.Now;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã gửi khóa học duyệt thành công. Vui lòng chờ quản trị viên phê duyệt." });
        }

        // ⑥ POST /api/instructor/courses/{courseId}/chapters — Tạo chương mới
        [HttpPost("courses/{courseId}/chapters")]
        public async Task<IActionResult> CreateChapter(int courseId, [FromBody] CreateChapterRequest request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == courseId);
            if (!isOwner) return Forbid();

            var chapter = new Chuong
            {
                TieuDe = request.TieuDe,
                MaKhoaHoc = courseId
            };
            _context.Chuongs.Add(chapter);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Thêm chương thành công.", chapterId = chapter.MaChuong });
        }

        // ⑦ POST /api/instructor/chapters/{chapterId}/lessons — Tạo bài học mới
        [HttpPost("chapters/{chapterId}/lessons")]
        public async Task<IActionResult> CreateLesson(int chapterId, [FromBody] CreateLessonRequest request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            // Kiểm tra chương này có thuộc khóa học mà instructor đang dạy không
            var chapter = await _context.Chuongs.Include(c => c.MaKhoaHocNavigation).FirstOrDefaultAsync(c => c.MaChuong == chapterId);
            if (chapter == null) return NotFound("Chương không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == chapter.MaKhoaHoc);
            if (!isOwner) return Forbid();

            var lesson = new BaiHoc
            {
                MaChuong = chapterId,
                LyThuyet = request.LyThuyet,
                BaiTap = request.BaiTap
            };
            _context.BaiHocs.Add(lesson);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Thêm bài học thành công.", lessonId = lesson.MaBaiHoc });
        }

        // ⑧ POST /api/instructor/lessons/{lessonId}/video — Upload video cho bài học
        [HttpPost("lessons/{lessonId}/video")]
        public async Task<IActionResult> UploadVideo(int lessonId, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Vui lòng chọn file video.");

            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var lesson = await _context.BaiHocs.Include(b => b.MaChuongNavigation).FirstOrDefaultAsync(b => b.MaBaiHoc == lessonId);
            if (lesson == null || lesson.MaChuongNavigation == null) return NotFound("Bài học không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == lesson.MaChuongNavigation.MaKhoaHoc);
            if (!isOwner) return Forbid();

            var uploadResult = await _cloudinaryService.UploadFileAsync(file, "courses/videos");
            if (string.IsNullOrEmpty(uploadResult))
                return BadRequest(new { message = "Lỗi khi upload video lên Cloudinary." });

            lesson.LinkVideo = uploadResult;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Upload video thành công.", linkVideo = lesson.LinkVideo });
        }

        // ⑨ POST /api/instructor/courses/{courseId}/cover — Upload ảnh bìa khóa học
        [HttpPost("courses/{courseId}/cover")]
        public async Task<IActionResult> UploadCourseCover(int courseId, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Vui lòng chọn file ảnh.");

            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == courseId);
            if (!isOwner) return Forbid();

            var course = await _context.KhoaHocs.FindAsync(courseId);
            if (course == null) return NotFound("Khóa học không tồn tại.");

            var uploadResult = await _cloudinaryService.UploadFileAsync(file, "courses/covers");
            if (string.IsNullOrEmpty(uploadResult))
                return BadRequest(new { message = "Lỗi khi upload ảnh lên Cloudinary." });

            course.AnhUrl = uploadResult;
            course.NgayCapNhat = DateTime.Now;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Upload ảnh khóa học thành công.", anhUrl = course.AnhUrl });
        }


        // ⑪ GET /api/instructor/courses/{courseId}/announcements — Lấy danh sách thông báo
        [HttpGet("courses/{courseId}/announcements")]
        public async Task<IActionResult> GetAnnouncements(int courseId)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == courseId);
            if (!isOwner) return Forbid();

            var list = await _context.ThongBaoKhoaHocs
                .Where(t => t.MaKhoaHoc == courseId)
                .OrderByDescending(t => t.NgayTao)
                .Select(t => new { t.MaThongBao, t.TieuDe, t.NoiDung, t.NgayTao })
                .ToListAsync();

            return Ok(list);
        }

        // ⑫ POST /api/instructor/courses/{courseId}/announcements — Tạo thông báo mới
        [HttpPost("courses/{courseId}/announcements")]
        public async Task<IActionResult> CreateAnnouncement(int courseId, [FromBody] CreateAnnouncementRequest request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == courseId);
            if (!isOwner) return Forbid();

            var tb = new ThongBaoKhoaHoc
            {
                MaKhoaHoc = courseId,
                TieuDe = request.TieuDe,
                NoiDung = request.NoiDung,
                NgayTao = DateTime.Now
            };

            _context.ThongBaoKhoaHocs.Add(tb);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo thông báo thành công.", id = tb.MaThongBao });
        }

        // ⑬ DELETE /api/instructor/announcements/{id} — Xóa thông báo
        [HttpDelete("announcements/{id}")]
        public async Task<IActionResult> DeleteAnnouncement(int id)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var tb = await _context.ThongBaoKhoaHocs.FindAsync(id);
            if (tb == null) return NotFound("Thông báo không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == tb.MaKhoaHoc);
            if (!isOwner) return Forbid();

            _context.ThongBaoKhoaHocs.Remove(tb);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa thông báo." });
        }

        // ⑩ DELETE /api/instructor/courses/{id} — Xóa khóa học (chỉ cho phép khi ở trạng thái Draft)
        [HttpDelete("courses/{id}")]
        public async Task<IActionResult> DeleteCourse(int id)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            // Kiểm tra quyền sở hữu
            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == id);
            if (!isOwner) return Forbid();

            var course = await _context.KhoaHocs
                .Include(k => k.Chuongs)
                    .ThenInclude(c => c.BaiHocs)
                .Include(k => k.GiangVienKhoaHocs)
                .FirstOrDefaultAsync(k => k.MaKhoaHoc == id);

            if (course == null)
                return NotFound(new { message = "Không tìm thấy khóa học." });

            // Chỉ cho phép xóa khóa học ở trạng thái Draft
            if (course.TinhTrang == "Published")
                return BadRequest(new { message = "Không thể xóa khóa học đã xuất bản." });

            // Soft Delete thay vì Hard Delete
            course.IsDeleted = true;
            course.NgayCapNhat = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Xóa khóa học thành công." });
        }

        private int? GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
                return userId;
            return null;
        }
    }

    public class CreateCourseRequest
    {
        public string TieuDe { get; set; } = null!;
        public string? TieuDePhu { get; set; }
        public string? MoTa { get; set; }
        public decimal? GiaGoc { get; set; }
        public int? MaTheLoai { get; set; }
        public string? KiNang { get; set; }
        public int? ThoiGianHocDuKien { get; set; }
        public int? ThoiGianChoPhepTre { get; set; }
    }

    public class UpdateCourseRequest : CreateCourseRequest
    {
        public string? TinhTrang { get; set; }
    }

    public class CreateChapterRequest
    {
        public string TieuDe { get; set; } = null!;
    }

    public class CreateLessonRequest
    {
        public string? LyThuyet { get; set; }
        public string? BaiTap { get; set; }
    }

    public class CreateAnnouncementRequest
    {
        public string TieuDe { get; set; } = null!;
        public string NoiDung { get; set; } = null!;
    }
}
