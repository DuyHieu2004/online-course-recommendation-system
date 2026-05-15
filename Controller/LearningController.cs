using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;

using Neo4j.Driver;
using online_course_recommendation_system.Configurations;
using Microsoft.Extensions.Options;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class LearningController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IDriver _neo4jDriver;
        private readonly Neo4jSettings _neo4jSettings;

        public LearningController(AppDbContext context, IDriver neo4jDriver, IOptions<Neo4jSettings> neo4jOptions)
        {
            _context = context;
            _neo4jDriver = neo4jDriver;
            _neo4jSettings = neo4jOptions.Value;
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
                    TinhTrang = t.TinhTrang == true ? "Đang học" : "Chưa bắt đầu",
                    t.NgayThamGia,
                    t.NgayKetThuc,
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
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var tienDo = await _context.TienDos
                .Include(t => t.TienDoBaiHocs)
                .FirstOrDefaultAsync(t => t.MaNguoiDung == userId.Value && t.MaKhoaHoc == courseId);

            if (tienDo == null)
                return StatusCode(403, new { message = "Bạn chưa đăng ký khóa học này." });

            if (tienDo.NgayKetThuc != null && tienDo.NgayKetThuc < DateTime.Now)
                return StatusCode(403, new { message = "Khóa học đã hết hạn. Vui lòng mua lại để tiếp tục học.", isExpired = true });

            var completedLessonIds = tienDo.TienDoBaiHocs
                .Where(x => x.DaHoanThanh == true)
                .Select(x => x.MaBaiHoc)
                .ToHashSet();

            var course = await _context.KhoaHocs
                .Include(k => k.Chuongs)
                    .ThenInclude(c => c.BaiHocs)
                .Include(k => k.Chuongs)
                    .ThenInclude(c => c.BaiKiemTras)
                .Include(k => k.GiangVienKhoaHocs)
                    .ThenInclude(gv => gv.MaGiangVienNavigation)
                .FirstOrDefaultAsync(k => k.MaKhoaHoc == courseId);

            if (course == null)
                return NotFound(new { message = "Không tìm thấy khóa học." });

            var hasCert = await _context.ChungChis
                .AnyAsync(c => c.MaNguoiDung == userId.Value && c.MaKhoaHoc == courseId);

            var result = new
            {
                course.MaKhoaHoc,
                course.TieuDe,
                PhanTramTienDo = tienDo.PhanTramTienDo,
                NgayThamGia = tienDo.NgayThamGia,
                NgayKetThuc = tienDo.NgayKetThuc,
                // Trả về link mẫu từ internet để test (tránh lỗi file trống trên server)
                LinkChungChi = (tienDo.PhanTramTienDo >= 100 || hasCert) 
                    ? "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" 
                    : null,
                GiangVien = course.GiangVienKhoaHocs
                    .Where(gv => gv.LaGiangVienChinh == true)
                    .Select(gv => gv.MaGiangVienNavigation?.Ten)
                    .FirstOrDefault(),
                Chuongs = course.Chuongs.Select(c => new
                {
                    c.MaChuong,
                    c.TieuDe,
                    BaiHocs = c.BaiHocs.Select(b => new
                    {
                        b.MaBaiHoc,
                        b.LyThuyet,
                        b.LinkVideo,
                        b.LinkTaiLieu,
                        b.BaiTap,
                        DaHoanThanh = completedLessonIds.Contains(b.MaBaiHoc),
                        ThoiGian = tienDo.TienDoBaiHocs.FirstOrDefault(x => x.MaBaiHoc == b.MaBaiHoc)?.ThoiGian ?? 0
                    }).ToList(),
                    BaiKiemTras = c.BaiKiemTras.Select(q => new
                    {
                        q.MaBaiKiemTra,
                        q.TieuDe,
                        q.ThoiGianLamBai
                    }).ToList()
                }).ToList()
            };

            return Ok(result);
        }

        // ⑤ POST /api/learning/enroll/{courseId} — Đăng ký khóa học (miễn phí hoặc trực tiếp)
        [HttpPost("enroll/{courseId}")]
        public async Task<IActionResult> EnrollCourse(int courseId)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var existingTienDo = await _context.TienDos.FirstOrDefaultAsync(t => t.MaNguoiDung == userId && t.MaKhoaHoc == courseId);
            
            var course = await _context.KhoaHocs.FindAsync(courseId);
            if (course == null)
                return NotFound(new { message = "Không tìm thấy khóa học." });

            bool isExpired = existingTienDo != null && existingTienDo.NgayKetThuc != null && existingTienDo.NgayKetThuc < DateTime.Now;

            if (existingTienDo != null && !isExpired)
                return BadRequest(new { message = "Bạn đã đăng ký khóa học này và vẫn còn hạn học." });

            var thoiGianHoc = course.ThoiGianHocDuKien ?? 0;
            var thoiGianTre = course.ThoiGianChoPhepTre ?? 0;
            DateTime? ngayKetThuc = null;
            if (thoiGianHoc > 0)
            {
                ngayKetThuc = DateTime.Now.AddMonths(thoiGianHoc).AddDays(thoiGianTre);
            }

            if (existingTienDo != null && isExpired)
            {
                // Cập nhật gia hạn
                existingTienDo.NgayThamGia = DateTime.Now;
                existingTienDo.NgayKetThuc = ngayKetThuc;
                // Giữ nguyên PhanTramTienDo và TinhTrang cũ
                _context.TienDos.Update(existingTienDo);
            }
            else
            {
                // Đăng ký mới
                var tienDo = new TienDo
                {
                    MaNguoiDung = userId.Value,
                    MaKhoaHoc = courseId,
                    NgayThamGia = DateTime.Now,
                    NgayKetThuc = ngayKetThuc,
                    PhanTramTienDo = 0,
                    TinhTrang = false // Chưa bắt đầu
                };
                _context.TienDos.Add(tienDo);
            }
            await _context.SaveChangesAsync();

            // ĐỒNG BỘ SANG NEO4J: Tạo quan hệ DANG_KY
            try
            {
                await using var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
                await session.RunAsync(@"
                    MATCH (u:NguoiDung {id: $userId})
                    MATCH (kh:KhoaHoc {id: $courseId})
                    MERGE (u)-[r:DANG_KY]->(kh)
                    ON CREATE SET r.ngayDangKy = datetime()
                    ON MATCH SET r.ngayGiaHan = datetime()", 
                    new { userId = userId.Value, courseId });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Neo4j Sync Error] Enrollment sync failed for user {userId}: {ex.Message}");
            }

            return Ok(new 
            { 
                message = "Đăng ký thành công!", 
                ngayKetThuc,
                ngayThamGia = existingTienDo?.NgayThamGia ?? DateTime.Now
            });
        }

        // ⑥ POST /api/learning/lesson/{lessonId}/time — Lưu lại thời gian đang xem video
        [HttpPost("lesson/{lessonId}/time")]
        public async Task<IActionResult> SaveLessonTime(int lessonId, [FromBody] int time)
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

            var existing = tienDo.TienDoBaiHocs.FirstOrDefault(tb => tb.MaBaiHoc == lessonId);
            if (existing != null)
            {
                // Chỉ cập nhật nếu thời gian mới lớn hơn thời gian cũ hoặc nếu chưa hoàn thành
                // Thực tế nên cho phép cập nhật bất cứ lúc nào để lưu vị trí xem mới nhất
                existing.ThoiGian = time;
                existing.LanCuoiXem = DateTime.Now;
            }
            else
            {
                _context.TienDoBaiHocs.Add(new TienDoBaiHoc
                {
                    MaTienDo = tienDo.MaTienDo,
                    MaBaiHoc = lessonId,
                    DaHoanThanh = false,
                    ThoiGian = time,
                    LanCuoiXem = DateTime.Now
                });
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã lưu tiến độ thời gian bài học." });
        }

        // ③ POST /api/learning/lesson/{lessonId}/complete — Hoàn thành bài học
        [HttpPost("lesson/{lessonId}/complete")]
        public async Task<IActionResult> CompleteLesson(int lessonId)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            try
            {
                var lesson = await _context.BaiHocs
                    .Include(b => b.MaChuongNavigation)
                    .FirstOrDefaultAsync(b => b.MaBaiHoc == lessonId);

                if (lesson == null || lesson.MaChuongNavigation == null)
                    return NotFound(new { message = "Không tìm thấy bài học." });

                var courseId = lesson.MaChuongNavigation.MaKhoaHoc;

                var tienDo = await _context.TienDos
                    .Include(t => t.TienDoBaiHocs)
                    .FirstOrDefaultAsync(t => t.MaKhoaHoc == courseId && t.MaNguoiDung == userId);

                if (tienDo == null)
                    return Forbidden("Bạn chưa đăng ký khóa học này.");

                var existing = tienDo.TienDoBaiHocs.FirstOrDefault(tb => tb.MaBaiHoc == lessonId);
                if (existing != null)
                {
                    if (existing.DaHoanThanh == true)
                    {
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

                await _context.SaveChangesAsync(); // Save before recalculating to ensure it's in the list

                // Tính lại phần trăm tiến độ
                var totalLessons = await _context.BaiHocs
                    .CountAsync(b => b.MaChuongNavigation != null && b.MaChuongNavigation.MaKhoaHoc == courseId);

                var completedLessons = await _context.TienDoBaiHocs
                    .CountAsync(tb => tb.MaTienDo == tienDo.MaTienDo && tb.DaHoanThanh == true);

                tienDo.PhanTramTienDo = totalLessons > 0 ? Math.Round((double)completedLessons / totalLessons * 100, 1) : 0;
                
                if (tienDo.PhanTramTienDo > 100) tienDo.PhanTramTienDo = 100;

                if (tienDo.PhanTramTienDo >= 100)
                {
                    tienDo.TinhTrang = true;
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
                return StatusCode(500, new { message = "Lỗi server: " + ex.Message });
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
