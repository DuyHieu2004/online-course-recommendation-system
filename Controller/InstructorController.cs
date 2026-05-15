using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using online_course_recommendation_system.Service;
using Neo4j.Driver;
using online_course_recommendation_system.Configurations;
using Microsoft.Extensions.Options;

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
        private readonly IDriver _neo4jDriver;
        private readonly Neo4jSettings _neo4jSettings;

        public InstructorController(AppDbContext context, IWebHostEnvironment env, ICloudinaryService cloudinaryService, IDriver neo4jDriver, IOptions<Neo4jSettings> neo4jOptions)
        {
            _context = context;
            _env = env;
            _cloudinaryService = cloudinaryService;
            _neo4jDriver = neo4jDriver;
            _neo4jSettings = neo4jOptions.Value;
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
                    gv.LaGiangVienChinh
                })
                .ToListAsync();

            return Ok(courses);
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
        public async Task<IActionResult> GetStats()
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var courseIds = await _context.GiangVienKhoaHocs
                .Where(gv => gv.MaGiangVien == userId.Value)
                .Select(gv => gv.MaKhoaHoc)
                .ToListAsync();

            var tongKhoaHoc = courseIds.Count;

            var tongHocVien = await _context.TienDos
                .Where(t => t.MaKhoaHoc.HasValue && courseIds.Contains(t.MaKhoaHoc.Value))
                .Select(t => t.MaNguoiDung)
                .Distinct()
                .CountAsync();

            var tbDanhGia = await _context.DanhGia
                .Where(d => d.MaKhoaHoc.HasValue && courseIds.Contains(d.MaKhoaHoc.Value) && d.Rating.HasValue)
                .AverageAsync(d => (double?)d.Rating) ?? 0;

            var tongDoanhThuRaw = await _context.ChiTietHoaDons
                .Where(ct => ct.MaKhoaHoc.HasValue && courseIds.Contains(ct.MaKhoaHoc.Value))
                .SumAsync(ct => ct.Gia ?? 0);
            
            var tongDoanhThu = tongDoanhThuRaw * 0.7m; // Giảng viên nhận 70%

            var tongDanhGia = await _context.DanhGia
                .Where(d => d.MaKhoaHoc.HasValue && courseIds.Contains(d.MaKhoaHoc.Value))
                .CountAsync();

            return Ok(new
            {
                tongKhoaHoc,
                tongHocVien,
                tbDanhGia = Math.Round(tbDanhGia, 1),
                tongDoanhThu,
                tongDanhGia
            });
        }

        // ③.5 GET /api/instructor/stats/revenue-series — Doanh thu theo tháng
        [HttpGet("stats/revenue-series")]
        public async Task<IActionResult> GetRevenueSeries([FromQuery] int year = 0)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            if (year == 0) year = DateTime.Now.Year;

            var courseIds = await _context.GiangVienKhoaHocs
                .Where(gv => gv.MaGiangVien == userId.Value)
                .Select(gv => gv.MaKhoaHoc)
                .ToListAsync();

            var rawData = await _context.ChiTietHoaDons
                .Include(ct => ct.MaHoaDonNavigation)
                .Where(ct => ct.MaKhoaHoc.HasValue && courseIds.Contains(ct.MaKhoaHoc.Value) &&
                             ct.MaHoaDonNavigation != null && ct.MaHoaDonNavigation.NgayTao.HasValue &&
                             ct.MaHoaDonNavigation.NgayTao.Value.Year == year && 
                             ct.MaHoaDonNavigation.TinhTrangThanhToan == true // chỉ tính đơn đã thanh toán
                             )
                .ToListAsync();

            var groupedData = rawData
                .GroupBy(ct => ct.MaHoaDonNavigation!.NgayTao!.Value.Month)
                .Select(g => new {
                    MonthNum = g.Key,
                    Revenue = g.Sum(ct => ct.Gia ?? 0)
                })
                .ToList();

            var result = Enumerable.Range(1, 12).Select(m => new {
                Month = $"T{m}",
                Revenue = groupedData.FirstOrDefault(d => d.MonthNum == m)?.Revenue ?? 0
            });

            return Ok(result);
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

                // Sync to Neo4j
                try {
                    var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
                    try {
                        await session.ExecuteWriteAsync(async tx => {
                            // Create Course node
                            await tx.RunAsync("MERGE (kh:KhoaHoc {id: $id}) SET kh.tieuDe = $tieuDe, kh.urlAnh = $urlAnh, kh.giaGoc = $giaGoc", 
                                new { id = course.MaKhoaHoc, tieuDe = course.TieuDe, urlAnh = course.AnhUrl, giaGoc = (double)(course.GiaGoc ?? 0) });
                            
                            // Link to Category
                            if (course.MaTheLoai.HasValue) {
                                await tx.RunAsync("MATCH (kh:KhoaHoc {id: $khId}), (t:TheLoai {id: $tId}) MERGE (kh)-[:THUOC_THE_LOAI]->(t)", 
                                    new { khId = course.MaKhoaHoc, tId = course.MaTheLoai.Value });
                            }
                        });
                    } finally {
                        await session.CloseAsync();
                    }
                } catch (Exception neoEx) {
                    Console.WriteLine($"[Neo4j Sync Error] Failed to sync created course {course.MaKhoaHoc}: {neoEx.Message}");
                }

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

            // Sync to Neo4j
            try {
                var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
                try {
                    await session.ExecuteWriteAsync(async tx => {
                        // Update Course node
                        await tx.RunAsync("MERGE (kh:KhoaHoc {id: $id}) SET kh.tieuDe = $tieuDe, kh.urlAnh = $urlAnh, kh.giaGoc = $giaGoc", 
                            new { id = id, tieuDe = course.TieuDe, urlAnh = course.AnhUrl, giaGoc = (double)(course.GiaGoc ?? 0) });
                        
                        // Update Category relationship
                        if (course.MaTheLoai.HasValue) {
                            await tx.RunAsync("MATCH (kh:KhoaHoc {id: $khId}) OPTIONAL MATCH (kh)-[r:THUOC_THE_LOAI]->() DELETE r", new { khId = id });
                            await tx.RunAsync("MATCH (kh:KhoaHoc {id: $khId}), (t:TheLoai {id: $tId}) MERGE (kh)-[:THUOC_THE_LOAI]->(t)", 
                                new { khId = id, tId = course.MaTheLoai.Value });
                        }
                    });
                } finally {
                    await session.CloseAsync();
                }
            } catch (Exception neoEx) {
                Console.WriteLine($"[Neo4j Sync Error] Failed to sync updated course {id}: {neoEx.Message}");
            }

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

            var chapter = await _context.Chuongs.FindAsync(chapterId);
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

        // ⑦.1 PUT /api/instructor/chapters/{id} — Cập nhật chương
        [HttpPut("chapters/{id}")]
        public async Task<IActionResult> UpdateChapter(int id, [FromBody] CreateChapterRequest request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var chapter = await _context.Chuongs.FindAsync(id);
            if (chapter == null) return NotFound("Chương không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == chapter.MaKhoaHoc);
            if (!isOwner) return Forbid();

            chapter.TieuDe = request.TieuDe;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật chương thành công." });
        }

        // ⑦.2 PUT /api/instructor/lessons/{id} — Cập nhật bài học (bao gồm chuyển chương)
        [HttpPut("lessons/{id}")]
        public async Task<IActionResult> UpdateLesson(int id, [FromBody] UpdateLessonRequest request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var lesson = await _context.BaiHocs.Include(b => b.MaChuongNavigation).FirstOrDefaultAsync(b => b.MaBaiHoc == id);
            if (lesson == null) return NotFound("Bài học không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == lesson.MaChuongNavigation.MaKhoaHoc);
            if (!isOwner) return Forbid();

            if (request.MaChuong.HasValue && request.MaChuong.Value != lesson.MaChuong)
            {
                // Kiểm tra chương mới có thuộc cùng khóa học không
                var targetChapter = await _context.Chuongs.FindAsync(request.MaChuong.Value);
                if (targetChapter == null || targetChapter.MaKhoaHoc != lesson.MaChuongNavigation.MaKhoaHoc)
                {
                    return BadRequest("Chương đích không hợp lệ hoặc không thuộc khóa học này.");
                }
                lesson.MaChuong = request.MaChuong.Value;
            }

            if (request.LyThuyet != null) lesson.LyThuyet = request.LyThuyet;
            if (request.BaiTap != null) lesson.BaiTap = request.BaiTap;
            
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật bài học thành công." });
        }

        // ⑧ POST /api/instructor/lessons/{lessonId}/video — Upload video cho bài học
        [HttpPost("lessons/{lessonId}/video")]
        [DisableRequestSizeLimit]
        [RequestFormLimits(MultipartBodyLengthLimit = 524288000)] // 500MB
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

        // ⑧.5 POST /api/instructor/lessons/{lessonId}/pdf — Upload tài liệu (PDF) cho bài học
        [HttpPost("lessons/{lessonId}/pdf")]
        [DisableRequestSizeLimit]
        [RequestFormLimits(MultipartBodyLengthLimit = 524288000)] // 500MB
        public async Task<IActionResult> UploadPdf(int lessonId, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Vui lòng chọn file tài liệu.");

            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var lesson = await _context.BaiHocs.Include(b => b.MaChuongNavigation).FirstOrDefaultAsync(b => b.MaBaiHoc == lessonId);
            if (lesson == null || lesson.MaChuongNavigation == null) return NotFound("Bài học không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == lesson.MaChuongNavigation.MaKhoaHoc);
            if (!isOwner) return Forbid();

            var uploadResult = await _cloudinaryService.UploadFileAsync(file, "courses/documents");
            if (string.IsNullOrEmpty(uploadResult))
                return BadRequest(new { message = "Lỗi khi upload tài liệu lên Cloudinary." });

            lesson.LinkTaiLieu = uploadResult;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Upload tài liệu thành công.", linkTaiLieu = lesson.LinkTaiLieu });
        }

        // ⑧.6 DELETE /api/instructor/lessons/{id} — Xóa bài học
        [HttpDelete("lessons/{id}")]
        public async Task<IActionResult> DeleteLesson(int id)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var lesson = await _context.BaiHocs.Include(b => b.MaChuongNavigation).FirstOrDefaultAsync(b => b.MaBaiHoc == id);
            if (lesson == null) return NotFound("Bài học không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == lesson.MaChuongNavigation.MaKhoaHoc);
            if (!isOwner) return Forbid();

            _context.BaiHocs.Remove(lesson);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Xóa bài học thành công." });
        }

        // ⑧.7 DELETE /api/instructor/chapters/{id} — Xóa chương
        [HttpDelete("chapters/{id}")]
        public async Task<IActionResult> DeleteChapter(int id)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var chapter = await _context.Chuongs.Include(c => c.BaiHocs).FirstOrDefaultAsync(c => c.MaChuong == id);
            if (chapter == null) return NotFound("Chương không tồn tại.");

            var isOwner = await _context.GiangVienKhoaHocs.AnyAsync(gv => gv.MaGiangVien == userId.Value && gv.MaKhoaHoc == chapter.MaKhoaHoc);
            if (!isOwner) return Forbid();

            // Xóa tất cả bài học trong chương trước (Cascading)
            if (chapter.BaiHocs != null && chapter.BaiHocs.Any())
            {
                _context.BaiHocs.RemoveRange(chapter.BaiHocs);
            }

            _context.Chuongs.Remove(chapter);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Xóa chương thành công." });
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

            // Sync to Neo4j
            var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
            try {
                await session.ExecuteWriteAsync(async tx => {
                    await tx.RunAsync("MATCH (kh:KhoaHoc {id: $id}) DETACH DELETE kh", new { id = id });
                });
            } finally {
                await session.CloseAsync();
            }

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
        public int? MaChuong { get; set; }
        public string? LyThuyet { get; set; }
        public string? BaiTap { get; set; }
    }

    public class UpdateLessonRequest : CreateLessonRequest { }

    public class CreateAnnouncementRequest
    {
        public string TieuDe { get; set; } = null!;
        public string NoiDung { get; set; } = null!;
    }
}
