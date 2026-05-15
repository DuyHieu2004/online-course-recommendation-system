using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Configurations;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.DTO;
using online_course_recommendation_system.Models;
using System.IO;
using System.Text.Json;
using Neo4j.Driver;
using Microsoft.Extensions.Options;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/users")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly Microsoft.AspNetCore.Hosting.IWebHostEnvironment _env;
        private readonly online_course_recommendation_system.Service.ICloudinaryService _cloudinaryService;
        private readonly IDriver _neo4jDriver;
        private readonly Neo4jSettings _neo4jSettings;

        public UsersController(
            AppDbContext context, 
            Microsoft.AspNetCore.Hosting.IWebHostEnvironment env, 
            online_course_recommendation_system.Service.ICloudinaryService cloudinaryService,
            IDriver neo4jDriver,
            IOptions<Neo4jSettings> neo4jOptions)
        {
            _context = context;
            _env = env;
            _cloudinaryService = cloudinaryService;
            _neo4jDriver = neo4jDriver;
            _neo4jSettings = neo4jOptions.Value;
        }

        [HttpGet("ping")]
        public IActionResult Ping() => Ok("pong");

        // ⑨ GET /api/users/notification-settings — Lấy cấu hình nhận thông báo
        [Authorize]
        [HttpGet("notification-settings")]
        public async Task<IActionResult> GetNotificationSettings()
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var user = await _context.NguoiDungs.FindAsync(userId.Value);
            if (user == null) return NotFound();

            var settingsPath = Path.Combine(Directory.GetCurrentDirectory(), "Data", "user_notifications.json");
            if (System.IO.File.Exists(settingsPath))
            {
                var json = await System.IO.File.ReadAllTextAsync(settingsPath);
                try {
                    var allSettings = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(json);
                    if (allSettings != null && allSettings.TryGetValue(userId.Value.ToString(), out var userSettings))
                    {
                        return Ok(userSettings);
                    }
                } catch { }
            }

            return Ok(GetDefaultSettings(user.VaiTro ?? "HocVien"));
        }

        // ⑩ POST /api/users/notification-settings — Cập nhật cấu hình nhận thông báo
        [Authorize]
        [HttpPost("notification-settings")]
        public async Task<IActionResult> UpdateNotificationSettings([FromBody] JsonElement settings)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var settingsPath = Path.Combine(Directory.GetCurrentDirectory(), "Data", "user_notifications.json");
            Dictionary<string, JsonElement> allSettings = new();

            if (System.IO.File.Exists(settingsPath))
            {
                var json = await System.IO.File.ReadAllTextAsync(settingsPath);
                try {
                    allSettings = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(json) ?? new();
                } catch { allSettings = new(); }
            }

            allSettings[userId.Value.ToString()] = settings;

            var dir = Path.GetDirectoryName(settingsPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir!);

            var updatedJson = JsonSerializer.Serialize(allSettings, new JsonSerializerOptions { WriteIndented = true });
            await System.IO.File.WriteAllTextAsync(settingsPath, updatedJson);

            return Ok(new { message = "Cập nhật cấu hình thông báo thành công!" });
        }


        // ① GET /api/users/profile — Xem profile bản thân (cần đăng nhập)
        [Authorize]
        [HttpGet("profile")]
        public async Task<IActionResult> GetMyProfile()
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var user = await _context.NguoiDungs.FindAsync(userId.Value);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản." });

            return Ok(MapToProfileDto(user));
        }

        // ② PUT /api/users/profile — Cập nhật profile bản thân (cần đăng nhập)
        [Authorize]
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateProfileDto request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var user = await _context.NguoiDungs.FindAsync(userId.Value);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản." });

            // Chỉ cập nhật những field được gửi lên (không null)
            if (request.Ten != null) user.Ten = request.Ten;
            if (request.TieuSu != null) user.TieuSu = request.TieuSu;
            if (request.LinkAnhDaiDien != null) user.LinkAnhDaiDien = request.LinkAnhDaiDien;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật profile thành công!", data = MapToProfileDto(user) });
        }

        // ②.1 POST /api/users/profile/degree — Up hồ sơ bằng cấp (Giảng viên)
        [Authorize]
        [HttpPost("profile/degree")]
        public async Task<IActionResult> UploadDegree(Microsoft.AspNetCore.Http.IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Vui lòng chọn file hợp lệ." });

            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized(new { message = "Token không hợp lệ." });

            var user = await _context.NguoiDungs.FindAsync(userId.Value);
            if (user == null) return NotFound(new { message = "Không tìm thấy tài khoản." });

            var uploadFolder = "documents";
            var url = await _cloudinaryService.UploadFileAsync(file, uploadFolder);

            if (string.IsNullOrEmpty(url))
            {
                return BadRequest(new { message = "Lỗi khi tải lên Cloudinary." });
            }

            user.HoSoBangCap = url;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tải lên hồ sơ thành công! Vui lòng chờ Admin duyệt tài khoản.", linkHoSo = user.HoSoBangCap });
        }

        // ②.5 DELETE /api/users/profile — Vô hiệu hóa tài khoản thân (chuyển sang "Bị khóa")
        [Authorize]
        [HttpDelete("profile")]
        public async Task<IActionResult> DeactivateMyProfile()
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var user = await _context.NguoiDungs.FindAsync(userId.Value);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản." });

            user.TinhTrang = "Bị khóa"; // Tương đương vô hiệu hóa
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tài khoản của bạn đã bị ngừng hoạt động." });
        }

        // ③ GET /api/users/{id} — Xem profile công khai (không cần đăng nhập)
        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetPublicProfile(int id)
        {
            var user = await _context.NguoiDungs.FindAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng." });

            // Trả về thông tin công khai — ẩn Email, TinhTrang
            return Ok(new
            {
                user.MaNguoiDung,
                user.Ten,
                user.VaiTro,
                user.LinkAnhDaiDien,
                user.TieuSu,
                user.NgayTao
            });
        }

        // ④ GET /api/users — Admin lấy danh sách users (phân trang + tìm kiếm)
        [Authorize(Roles = "Admin")]
        [HttpGet]
        public async Task<IActionResult> GetAllUsers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? search = null,
            [FromQuery] string? vaiTro = null)
        {
            var query = _context.NguoiDungs.AsQueryable();

            // Tìm kiếm theo tên hoặc email
            if (!string.IsNullOrWhiteSpace(search))
            {
                query = query.Where(u => u.Ten.Contains(search) || u.Email.Contains(search));
            }

            // Lọc theo vai trò (HocVien, GiaoVien, Admin)
            if (!string.IsNullOrWhiteSpace(vaiTro))
            {
                query = query.Where(u => u.VaiTro == vaiTro);
            }

            var totalCount = await query.CountAsync();

            var users = await query
                .OrderByDescending(u => u.NgayTao)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(u => new UserProfileDto
                {
                    MaNguoiDung = u.MaNguoiDung,
                    Ten = u.Ten,
                    Email = u.Email,
                    VaiTro = u.VaiTro,
                    LinkAnhDaiDien = u.LinkAnhDaiDien,
                    TieuSu = u.TieuSu,
                    TinhTrang = u.TinhTrang,
                    NgayTao = u.NgayTao,
                    HoSoBangCap = u.HoSoBangCap
                })
                .ToListAsync();

            return Ok(new
            {
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling((double)totalCount / pageSize),
                data = users
            });
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("admin")]
        public async Task<IActionResult> CreateAdmin([FromBody] RegisterDto request)
        {
            if (await _context.NguoiDungs.AnyAsync(u => u.Email == request.Email))
                return BadRequest(new { message = "Email này đã được sử dụng!" });

            // Hàm băm mật khẩu nội bộ dùng tạm SHA256 (nên dùng BCrypt trong thực tế)
            var user = new online_course_recommendation_system.Models.NguoiDung
            {
                Ten = request.Ten,
                Email = request.Email,
                MatKhau = HashPassword(request.MatKhau),
                VaiTro = "Admin",
                TinhTrang = "Hoạt động",
                NgayTao = DateTime.Now
            };

            _context.NguoiDungs.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo quản trị viên thành công!", data = MapToProfileDto(user) });
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("stats")]
        public async Task<IActionResult> GetAdminStats()
        {
            var totalUsers = await _context.NguoiDungs.CountAsync();
            var students = await _context.NguoiDungs.CountAsync(u => u.VaiTro == "HocVien");
            var instructors = await _context.NguoiDungs.CountAsync(u => u.VaiTro == "GiaoVien");
            var admins = await _context.NguoiDungs.CountAsync(u => u.VaiTro == "Admin");

            var totalRevenueRaw = await _context.ChiTietHoaDons.SumAsync(ct => ct.Gia ?? 0);
            var adminRevenue = totalRevenueRaw * 0.3m;

            return Ok(new
            {
                totalUsers,
                students,
                instructors,
                admins,
                adminRevenue
            });
        }

        // ⑤ PUT /api/users/{id}/role — Admin thay đổi vai trò
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}/role")]
        public async Task<IActionResult> UpdateRole(int id, [FromBody] UpdateRoleDto request)
        {
            try
            {
                // Validate vai trò hợp lệ
                var validRoles = new[] { "HocVien", "GiaoVien", "Admin" };
                if (!validRoles.Contains(request.VaiTro))
                    return BadRequest(new { message = $"Vai trò không hợp lệ. Chỉ chấp nhận: {string.Join(", ", validRoles)}" });

                // Không cho Admin tự hạ vai trò chính mình
                var currentUserId = GetUserIdFromToken();
                if (currentUserId == id)
                    return BadRequest(new { message = "Không thể thay đổi vai trò của chính mình." });

                var user = await _context.NguoiDungs.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Không tìm thấy người dùng." });

                user.VaiTro = request.VaiTro;
                await _context.SaveChangesAsync();

                return Ok(new { message = $"Đã cập nhật vai trò của '{user.Ten}' thành '{request.VaiTro}'." });
            }
            catch (Exception ex)
            {
                var innerMsg = ex.InnerException?.Message ?? ex.Message;
                return StatusCode(500, new { message = $"Lỗi server: {innerMsg}" });
            }
        }

        // ⑥ PUT /api/users/{id}/status — Admin khóa/mở khóa tài khoản
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusDto request)
        {
            // Validate trạng thái hợp lệ
            var validStatuses = new[] { "Hoạt động", "Bị khóa" };
            if (!validStatuses.Contains(request.TinhTrang))
                return BadRequest(new { message = $"Trạng thái không hợp lệ. Chỉ chấp nhận: {string.Join(", ", validStatuses)}" });

            // Không cho Admin tự khóa chính mình
            var currentUserId = GetUserIdFromToken();
            if (currentUserId == id)
                return BadRequest(new { message = "Không thể thay đổi trạng thái của chính mình." });

            var user = await _context.NguoiDungs.FindAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng." });

            user.TinhTrang = request.TinhTrang;
            await _context.SaveChangesAsync();

            return Ok(new { message = $"Đã cập nhật trạng thái của '{user.Ten}' thành '{request.TinhTrang}'." });
        }

        // ⑦ GET /api/users/notifications — Lấy danh sách thông báo của bản thân
        [Authorize]
        [HttpGet("notifications")]
        public async Task<IActionResult> GetMyNotifications()
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var notifications = await _context.ThongBaos
                .Where(t => t.MaNguoiDung == userId.Value)
                .OrderByDescending(t => t.NgayTao)
                .Take(50) // Giới hạn lấy 50 thông báo gần nhất
                .Select(t => new
                {
                    t.MaThongBao,
                    t.TieuDe,
                    t.NoiDung,
                    t.NgayTao,
                    t.DaDoc
                })
                .ToListAsync();

            var unreadCount = await _context.ThongBaos.CountAsync(t => t.MaNguoiDung == userId.Value && !t.DaDoc);

            return Ok(new { data = notifications, unreadCount });
        }

        // ⑧ PUT /api/users/notifications/{id}/read — Đánh dấu đã đọc
        [Authorize]
        [HttpPut("notifications/{id}/read")]
        public async Task<IActionResult> MarkNotificationAsRead(int id)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var notif = await _context.ThongBaos.FirstOrDefaultAsync(t => t.MaThongBao == id && t.MaNguoiDung == userId.Value);
            if (notif == null) return NotFound(new { message = "Không tìm thấy thông báo." });

            notif.DaDoc = true;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã đánh dấu đọc." });
        }

        // ⑪ GET /api/users/interests — Lấy danh sách sở thích (thể loại) của người dùng
        [Authorize]
        [HttpGet("interests")]
        public async Task<IActionResult> GetMyInterests()
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            Console.WriteLine($"[API] Đang lấy sở thích cho User ID: {userId}");

            var interests = await _context.SoThichNguoiDungs
                .Where(s => s.MaNguoiDung == userId.Value)
                .Select(s => new {
                    s.MaTheLoai,
                    TenTheLoai = s.MaTheLoaiNavigation.Ten
                })
                .ToListAsync();

            return Ok(interests);
        }

        // ⑫ POST /api/users/interests — Cập nhật danh sách sở thích
        [Authorize]
        [HttpPost("interests")]
        public async Task<IActionResult> UpdateMyInterests([FromBody] List<int> categoryIds)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            // 1. Xóa sở thích cũ trong SQL
            var oldInterests = _context.SoThichNguoiDungs.Where(s => s.MaNguoiDung == userId.Value);
            _context.SoThichNguoiDungs.RemoveRange(oldInterests);

            // 2. Thêm sở thích mới
            foreach (var catId in categoryIds)
            {
                _context.SoThichNguoiDungs.Add(new SoThichNguoiDung
                {
                    MaNguoiDung = userId.Value,
                    MaTheLoai = catId,
                    NgayTao = DateTime.Now
                });
            }
            await _context.SaveChangesAsync();

            // 3. Đồng bộ sang Neo4j
            try
            {
                await using var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
                
                // Xóa các quan hệ QUAN_TAM cũ
                await session.RunAsync("MATCH (u:NguoiDung {id: $userId})-[r:QUAN_TAM]->() DELETE r", new { userId = userId.Value });
                
                // Thêm quan hệ QUAN_TAM mới
                if (categoryIds.Any())
                {
                    await session.RunAsync(@"
                        MERGE (u:NguoiDung {id: $userId})
                        WITH u
                        MATCH (t:TheLoai) WHERE t.id IN $catIds
                        MERGE (u)-[:QUAN_TAM]->(t)", 
                        new { userId = userId.Value, catIds = categoryIds });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Neo4j Sync Error] Interests update failed for user {userId}: {ex.Message}");
            }

            return Ok(new { message = "Cập nhật sở thích thành công!" });
        }

        private object GetDefaultSettings(string vaiTro)
        {
            if (vaiTro == "GiaoVien")
            {
                return new[]
                {
                    new { id = "enrollment", label = "Học viên mới đăng ký", enabled = true },
                    new { id = "review", label = "Đánh giá mới", enabled = true },
                    new { id = "revenue", label = "Báo cáo doanh thu", enabled = true },
                    new { id = "approval", label = "Trạng thái khóa học", enabled = true },
                    new { id = "promotion", label = "Khuyến mãi hệ thống", enabled = false }
                };
            }

            return new[]
            {
                new { id = "purchase", label = "Xác nhận mua khóa học", enabled = true },
                new { id = "expiry", label = "Nhắc nhở quá hạn", enabled = true },
                new { id = "update", label = "Cập nhật nội dung", enabled = true },
                new { id = "promotion", label = "Khuyến mãi & Ưu đãi", enabled = false }
            };
        }

        // ==========================================
        // HÀM HỖ TRỢ
        // ==========================================

        private string HashPassword(string password)
        {
            using (var sha256 = System.Security.Cryptography.SHA256.Create())
            {
                var bytes = System.Text.Encoding.UTF8.GetBytes(password);
                var hash = sha256.ComputeHash(bytes);
                return Convert.ToBase64String(hash);
            }
        }

        private int? GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
                return userId;
            return null;
        }

        private static UserProfileDto MapToProfileDto(Models.NguoiDung user)
        {
            return new UserProfileDto
            {
                MaNguoiDung = user.MaNguoiDung,
                Ten = user.Ten,
                Email = user.Email,
                VaiTro = user.VaiTro,
                LinkAnhDaiDien = user.LinkAnhDaiDien,
                TieuSu = user.TieuSu,
                TinhTrang = user.TinhTrang,
                NgayTao = user.NgayTao,
                HoSoBangCap = user.HoSoBangCap
            };
        }
    }
}
