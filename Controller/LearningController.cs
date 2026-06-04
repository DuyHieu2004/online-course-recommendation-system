using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class LearningController : ControllerBase
    {
        private readonly AppDbContext _context;

        public LearningController(AppDbContext context)
        {
            _context = context;
        }

        private async Task CheckAndNotifyExpirationsAsync(int userId)
        {
            var today = DateTime.Now;
            var warningDate = today.AddMonths(1);

            var tienDos = await _context.TienDos
                .Include(t => t.MaKhoaHocNavigation)
                .Where(t => t.MaNguoiDung == userId)
                .ToListAsync();

            bool hasChanges = false;

            foreach (var t in tienDos)
            {
                if (t.NgayKetThuc == null) continue;

                // 1. Nếu ĐÃ HẾT HẠN: Khóa bất kể đã xong hay chưa
                if (t.NgayKetThuc.Value < today && t.TinhTrang == true)
                {
                    t.TinhTrang = false; 
                    _context.ThongBaos.Add(new ThongBao {
                        MaNguoiDung = userId,
                        TieuDe = "⏳ Quyền truy cập khóa học đã hết",
                        NoiDung = $"Khóa học '{t.MaKhoaHocNavigation?.TieuDe}' đã hết thời hạn 1 năm truy cập. Hệ thống đã đóng quyền xem lại bài học.",
                        NgayTao = DateTime.Now
                    });
                }
                // 2. Nếu SẮP HẾT HẠN: CHỈ thông báo cho người CHƯA HOÀN THÀNH (< 100%)
                else if (t.NgayKetThuc.Value <= warningDate && t.NgayKetThuc.Value >= today 
                        && t.TinhTrang == true && (t.PhanTramTienDo ?? 0) < 100)
                {
                    // Kiểm tra xem 7 ngày gần đây đã nhắc chưa (tránh spam)
                    var daNhacNho = await _context.ThongBaos.AnyAsync(tb => 
                        tb.MaNguoiDung == userId && 
                        tb.TieuDe.Contains("Sắp hết hạn") && 
                        tb.NoiDung.Contains(t.MaKhoaHocNavigation.TieuDe) &&
                        tb.NgayTao > today.AddDays(-7));

                    if (!daNhacNho)
                    {
                        _context.ThongBaos.Add(new ThongBao
                        {
                            MaNguoiDung = userId,
                            TieuDe = "⚠️ Cảnh báo: Khóa học sắp hết hạn",
                            NoiDung = $"Khóa học '{t.MaKhoaHocNavigation?.TieuDe}' sẽ hết hạn vào ngày {t.NgayKetThuc.Value:dd/MM/yyyy}. Hãy nhanh chóng hoàn thành nhé!",
                            NgayTao = DateTime.Now,
                            DaDoc = false
                        });
                        hasChanges = true;
                    }
                }
            }

            if (hasChanges) await _context.SaveChangesAsync();
        }

        // ① GET /api/learning/my-courses — Khóa học đã đăng ký + tiến độ (Phân trang)
        [HttpGet("my-courses")]
        public async Task<IActionResult> GetMyCourses(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            await CheckAndNotifyExpirationsAsync(userId.Value);

            var query = _context.TienDos
                .Where(t => t.MaNguoiDung == userId.Value);

            var totalCount = await query.CountAsync();

            var enrolledCourses = await query
                .Include(t => t.MaKhoaHocNavigation)
                    .ThenInclude(k => k!.MaTheLoaiNavigation)
                .Include(t => t.MaKhoaHocNavigation)
                    .ThenInclude(k => k!.GiangVienKhoaHocs)
                        .ThenInclude(gv => gv.MaGiangVienNavigation)
                .Include(t => t.MaKhoaHocNavigation)
                    .ThenInclude(k => k!.Chuongs)
                .OrderByDescending(t => t.NgayThamGia)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(t => new
                {
                    t.MaTienDo,
                    t.PhanTramTienDo,
                    TinhTrang = t.TinhTrang == true ? "Đang học" : "Đã hết hạn",
                    t.NgayThamGia,
                    KhoaHoc = t.MaKhoaHocNavigation == null ? null : new
                    {
                        t.MaKhoaHocNavigation.MaKhoaHoc,
                        t.MaKhoaHocNavigation.TieuDe,
                        t.MaKhoaHocNavigation.AnhUrl,
                        t.MaKhoaHocNavigation.TbdanhGia,
                        TheLoai = t.MaKhoaHocNavigation.MaTheLoaiNavigation != null
                            ? t.MaKhoaHocNavigation.MaTheLoaiNavigation.Ten : null,
                        GiangVien = t.MaKhoaHocNavigation.GiangVienKhoaHocs
                            .Where(gv => gv.LaGiangVienChinh == true)
                            .Select(gv => gv.MaGiangVienNavigation.Ten)
                            .FirstOrDefault(),
                        SoLuongChuong = t.MaKhoaHocNavigation.Chuongs.Count
                    }
                })
                .ToListAsync();

            return Ok(new
            {
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling((double)totalCount / pageSize),
                data = enrolledCourses
            });
        }

        // ② GET /api/learning/course/{courseId} — Nội dung học (chương, bài, tiến độ)
        [HttpGet("course/{courseId}")]
        public async Task<IActionResult> GetCourseContent(int courseId)
        {
            try
            {
                var userId = GetUserIdFromToken();
                if (userId == null)
                    return Unauthorized(new { message = "Token không hợp lệ." });

                var tienDo = await _context.TienDos
                    .Include(t => t.TienDoBaiHocs)
                    .FirstOrDefaultAsync(t => t.MaNguoiDung == userId.Value && t.MaKhoaHoc == courseId);

                if (tienDo == null)
                    return StatusCode(403, new { message = "Bạn chưa đăng ký khóa học này." });

                // THÊM ĐOẠN NÀY ĐỂ CHẶN TRUY CẬP
                if (tienDo.NgayKetThuc.HasValue && tienDo.NgayKetThuc.Value < DateTime.Now)
                {
                    return StatusCode(403, new { message = "Khóa học này đã hết hạn. Vui lòng mua lại để giữ nguyên tiến độ và tiếp tục học." });
                }

                // Fix 1: Thêm toán tử ?? để đảm bảo không bị lỗi nếu TienDoBaiHocs là null
                var completedLessonIds = (tienDo.TienDoBaiHocs ?? new List<TienDoBaiHoc>())
                    .Where(x => x.DaHoanThanh == true)
                    .Select(x => x.MaBaiHoc)
                    .ToHashSet();

                var course = await _context.KhoaHocs
                    .Include(k => k.Chuongs)
                        .ThenInclude(c => c.BaiHocs)
                    // ĐÃ BỎ Include BaiKiemTras ở đây
                    .Include(k => k.GiangVienKhoaHocs)
                        .ThenInclude(gv => gv.MaGiangVienNavigation)
                    .FirstOrDefaultAsync(k => k.MaKhoaHoc == courseId);

                if (course == null)
                    return NotFound(new { message = "Không tìm thấy khóa học." });

                // Fix 2: Thêm dấu '?' (Null-conditional operator) trước các hàm LINQ
                var result = new
                {
                    course.MaKhoaHoc,
                    course.TieuDe,
                    PhanTramTienDo = tienDo.PhanTramTienDo,
                    GiangVien = course.GiangVienKhoaHocs?
                        .Where(gv => gv.LaGiangVienChinh == true)
                        .Select(gv => gv.MaGiangVienNavigation?.Ten)
                        .FirstOrDefault(),
                    Chuongs = course.Chuongs?.Select(c => new
                    {
                        c.MaChuong,
                        c.TieuDe,
                        BaiHocs = c.BaiHocs?.Select(b => new
                        {
                            b.MaBaiHoc,
                            b.LyThuyet,
                            b.LinkVideo,
                            b.BaiTap,
                            b.LinkTaiLieu,
                            DaHoanThanh = completedLessonIds.Contains(b.MaBaiHoc)
                        }).ToList()
                        // ĐÃ BỎ thuộc tính BaiKiemTras ở đây
                    }).ToList()
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                // Fix 3: Bọc try-catch để nếu có lỗi khác, FE sẽ nhận được thông báo rõ ràng thay vì crash ngầm
                var innerMsg = ex.InnerException != null ? ex.InnerException.Message : "";
                return StatusCode(500, new { message = "Lỗi khi tải nội dung: " + ex.Message, details = innerMsg });
            }
        }

        // ③ POST /api/learning/lesson/{lessonId}/complete — Đánh dấu hoàn thành bài học
        [HttpPost("lesson/{lessonId}/complete")]
        public async Task<IActionResult> CompleteLesson(int lessonId)
        {
            try
            {
                var userId = GetUserIdFromToken();
                if (userId == null)
                    return Unauthorized(new { message = "Token không hợp lệ." });

                // Tìm bài học
                var lesson = await _context.BaiHocs
                    .Include(b => b.MaChuongNavigation)
                    .FirstOrDefaultAsync(b => b.MaBaiHoc == lessonId);

                if (lesson == null)
                    return NotFound(new { message = "Không tìm thấy bài học." });

                var courseId = lesson.MaChuongNavigation?.MaKhoaHoc;

                // Tìm tiến độ
                var tienDo = await _context.TienDos
                    .Include(t => t.TienDoBaiHocs)
                    .FirstOrDefaultAsync(t => t.MaNguoiDung == userId.Value && t.MaKhoaHoc == courseId);

                if (tienDo == null)
                    return BadRequest(new { message = "Bạn chưa đăng ký khóa học này." });

                // Kiểm tra đã hoàn thành chưa
                var existing = tienDo.TienDoBaiHocs.FirstOrDefault(tb => tb.MaBaiHoc == lessonId);
                if (existing != null)
                {
                    if (existing.DaHoanThanh == true)
                    {
                        // Đã hoàn thành rồi, không cần tính lại
                        return Ok(new
                        {
                            message = "Bài học này đã hoàn thành.",
                            phanTramTienDo = tienDo.PhanTramTienDo
                        });
                    }

                    existing.DaHoanThanh = true;
                    existing.LanCuoiXem = DateTime.Now;
                }
                else
                {
                    _context.TienDoBaiHocs.Add(new TienDoBaiHoc
                    {
                        MaTienDo = tienDo.MaTienDo,
                        MaBaiHoc = lessonId,
                        DaHoanThanh = true,
                        LanCuoiXem = DateTime.Now
                    });
                }

                // Tính lại phần trăm tiến độ
                var totalLessons = await _context.BaiHocs
                    .CountAsync(b => b.MaChuongNavigation != null && b.MaChuongNavigation.MaKhoaHoc == courseId);

                var completedLessons = tienDo.TienDoBaiHocs.Count(tb => tb.DaHoanThanh == true);
                if (existing == null || existing.DaHoanThanh != true)
                    completedLessons += 1; // Vừa hoàn thành thêm 1

                tienDo.PhanTramTienDo = totalLessons > 0 ? Math.Round((double)completedLessons / totalLessons * 100, 1) : 0;
                
                // Đảm bảo phần trăm không bao giờ vượt quá 100 (phòng tránh vi phạm CHECK constraint trong CSDL)
                if (tienDo.PhanTramTienDo > 100)
                {
                    tienDo.PhanTramTienDo = 100;
                }

                // Nếu hoàn thành 100% → cấp chứng chỉ
                if (tienDo.PhanTramTienDo >= 100)
                {
                    tienDo.TinhTrang = true; // Hoàn thành

                    var hasCert = await _context.ChungChis
                        .AnyAsync(c => c.MaNguoiDung == userId.Value && c.MaKhoaHoc == courseId);

                    if (!hasCert)
                    {
                        _context.ChungChis.Add(new ChungChi
                        {
                            MaNguoiDung = userId.Value,
                            MaKhoaHoc = courseId,
                            NgayPhat = DateTime.Now
                        });
                    }
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Đã hoàn thành bài học!",
                    phanTramTienDo = tienDo.PhanTramTienDo
                });
            }
            catch (Exception ex)
            {
                var innerMsg = ex.InnerException != null ? ex.InnerException.Message : "";
                return StatusCode(500, new { message = "Lỗi server: " + ex.Message + " | Chi tiết: " + innerMsg });
            }
        }

        // ④ GET /api/learning/certificates — Chứng chỉ đã nhận
        [HttpGet("certificates")]
        public async Task<IActionResult> GetCertificates()
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var certificates = await _context.ChungChis
                .Where(c => c.MaNguoiDung == userId.Value)
                .Include(c => c.MaKhoaHocNavigation)
                .Select(c => new
                {
                    c.MaChungChi,
                    c.NgayPhat,
                    KhoaHoc = c.MaKhoaHocNavigation == null ? null : new
                    {
                        c.MaKhoaHocNavigation.MaKhoaHoc,
                        c.MaKhoaHocNavigation.TieuDe,
                        c.MaKhoaHocNavigation.AnhUrl
                    }
                })
                .ToListAsync();

            return Ok(certificates);
        }

        private int? GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
                return userId;
            return null;
        }

        private IActionResult Forbidden(string message)
        {
            return StatusCode(403, new { message });
        }
    }
}
