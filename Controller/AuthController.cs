using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;
using online_course_recommendation_system.DTO; 
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _env;
        private readonly online_course_recommendation_system.Service.ICloudinaryService _cloudinaryService;

        // Tiêm AppDbContext để tương tác DB và IConfiguration để lấy cấu hình từ appsettings.json
        public AuthController(AppDbContext context, IConfiguration configuration, IWebHostEnvironment env, online_course_recommendation_system.Service.ICloudinaryService cloudinaryService)
        {
            _context = context;
            _configuration = configuration;
            _env = env;
            _cloudinaryService = cloudinaryService;
        }

        // --- API ĐĂNG KÝ ---
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromForm] RegisterDto request)
        {
            // Kiểm tra xem email đã tồn tại dưới Database chưa
            if (await _context.NguoiDungs.AnyAsync(u => u.Email == request.Email))
                return BadRequest(new { message = "Email này đã được sử dụng!" });

            var vaiTro = request.VaiTro == "instructor" || request.VaiTro == "GiaoVien" ? "GiaoVien" : "HocVien";
            var tinhTrang = vaiTro == "GiaoVien" ? "Chờ duyệt" : "Active";
            
            string? degreeUrl = null;

            if (request.File != null && vaiTro == "GiaoVien")
            {
                // Kiểm tra định dạng
                var extension = Path.GetExtension(request.File.FileName).ToLower();
                var allowedExtensions = new[] { ".pdf", ".jpg", ".jpeg", ".png" };
                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest(new { message = "Chỉ chấp nhận file PDF hoặc hình ảnh (JPG, PNG)." });
                }

                // Giới hạn kích thước (vd 5MB)
                if (request.File.Length > 5 * 1024 * 1024)
                {
                    return BadRequest(new { message = "Kích thước file không được vượt quá 5MB." });
                }

                // Upload lên Cloudinary
                degreeUrl = await _cloudinaryService.UploadFileAsync(request.File, "degrees");
                
                if (string.IsNullOrEmpty(degreeUrl))
                {
                    return BadRequest(new { message = "Lỗi khi tải lên Cloudinary." });
                }
            }

            // Tạo Object NguoiDung mới dựa theo Models/NguoiDung.cs
            var user = new NguoiDung
            {
                Ten = request.Ten,
                Email = request.Email,
                MatKhau = HashPassword(request.MatKhau), // Mã hóa mật khẩu cho an toàn
                VaiTro = vaiTro, 
                TinhTrang = tinhTrang,
                HoSoBangCap = degreeUrl,
                NgayTao = DateTime.Now
            };

            // Lưu xuống Database
            _context.NguoiDungs.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đăng ký thành công!", userId = user.MaNguoiDung });
        }

        // --- API ĐĂNG NHẬP & CẤP TOKEN ---
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto request)
        {
            // Tìm user trong DB theo Email
            var user = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.Email == request.Email);
            
            // Nếu không tìm thấy hoặc sai mật khẩu
            if (user == null || user.MatKhau != HashPassword(request.MatKhau))
                return Unauthorized(new { message = "Email hoặc mật khẩu không chính xác." });

            if (user.TinhTrang == "Chờ duyệt")
                return Unauthorized(new { message = "Tài khoản của bạn đang chờ Admin duyệt hồ sơ. Vui lòng thử lại sau." });

            if (user.TinhTrang == "Từ chối")
                return Unauthorized(new { message = "Hồ sơ của bạn đã bị từ chối. Vui lòng liên hệ Admin." });

            // Khóa không cho User bị khóa đăng nhập
            if (user.TinhTrang != "Hoạt động" && user.TinhTrang != "Active")
                return Unauthorized(new { message = "Tài khoản của bạn đã bị khóa hoặc ngừng hoạt động." });

            // Tạo chuỗi JWT Token
            var token = GenerateJwtToken(user);

            return Ok(new 
            { 
                message = "Đăng nhập thành công", 
                token = token,
                role = user.VaiTro,
                userId = user.MaNguoiDung,
                userName = user.Ten,
                status = user.TinhTrang
            });
        }

        // --- API QUÊN MẬT KHẨU ---
        // (Lưu ý: Bạn cũng nên tạo ForgotPasswordDto.cs trong thư mục DTO giống LoginDto)
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto request)
        {
            var user = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản với email này." });

            // Demo: Reset mật khẩu thành "123456" và lưu lại xuống DB
            // Thực tế triển khai: Nên gửi Email chứa OTP hoặc link reset mật khẩu
            user.MatKhau = HashPassword("123456");
            await _context.SaveChangesAsync(); 

            return Ok(new { message = "Mật khẩu của bạn đã được reset về mặc định: 123456" });
        }


        // --- API ĐỔI MẬT KHẨU ---
        [Microsoft.AspNetCore.Authorization.Authorize]
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto request)
        {
            // Lấy UserId từ JWT Token
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim == null || !int.TryParse(userIdClaim, out int userId))
                return Unauthorized(new { message = "Token không hợp lệ." });

            var user = await _context.NguoiDungs.FindAsync(userId);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản." });

            // Kiểm tra mật khẩu cũ
            if (user.MatKhau != HashPassword(request.MatKhauCu))
                return BadRequest(new { message = "Mật khẩu hiện tại không đúng." });

            // Cập nhật mật khẩu mới
            user.MatKhau = HashPassword(request.MatKhauMoi);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đổi mật khẩu thành công!" });
        }

        // ==========================================
        // CÁC HÀM HỖ TRỢ XỬ LÝ NGHIỆP VỤ BÊN DƯỚI
        // ==========================================

        // Hàm băm mật khẩu ra chuỗi mã hóa (SHA256)
        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }

        // Hàm tạo chữ ký JWT Token chuẩn
        private string GenerateJwtToken(NguoiDung user)
        {
            var jwtSettings = _configuration.GetSection("Jwt");
            
            // Lấy thông tin từ appsettings.json. Quăng lỗi ngay nếu lập trình viên quên cấu hình!
            var secretKey = jwtSettings["Key"] ?? throw new InvalidOperationException("Thiếu cấu hình Jwt:Key trong appsettings.json");
            var issuer = jwtSettings["Issuer"] ?? throw new InvalidOperationException("Thiếu cấu hình Jwt:Issuer trong appsettings.json");
            var audience = jwtSettings["Audience"] ?? throw new InvalidOperationException("Thiếu cấu hình Jwt:Audience trong appsettings.json");

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            // Các thông tin (Payload) đính kèm vào Token
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Email),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.Name, user.Ten),
                new Claim(ClaimTypes.Role, user.VaiTro ?? "HocVien"),
                new Claim("UserId", user.MaNguoiDung.ToString())
            };

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.Now.AddDays(1), // Token có hạn 1 ngày
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}