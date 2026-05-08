using Microsoft.AspNetCore.Mvc;
using online_course_recommendation_system.Models;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using System.Net;
using System.Net.Mail;

namespace online_course_recommendation_system.Controller
{
    [ApiController]
    [Route("api/[controller]")]
    public class SettingsController : ControllerBase
    {
        private readonly string _settingsPath = Path.Combine(Directory.GetCurrentDirectory(), "Data", "systemsettings.json");

        [HttpGet]
        public async Task<IActionResult> GetSettings()
        {
            if (!System.IO.File.Exists(_settingsPath))
            {
                return Ok(new GlobalSettings());
            }

            var json = await System.IO.File.ReadAllTextAsync(_settingsPath);
            var settings = JsonSerializer.Deserialize<GlobalSettings>(json);
            return Ok(settings);
        }

        [HttpPost]
        public async Task<IActionResult> UpdateSettings([FromBody] GlobalSettings settings)
        {
            var json = JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true });
            
            // Ensure directory exists
            var dir = Path.GetDirectoryName(_settingsPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir!);

            await System.IO.File.WriteAllTextAsync(_settingsPath, json);
            return Ok(new { message = "Settings updated successfully" });
        }

        [HttpPost("test-email")]
        public async Task<IActionResult> TestEmail([FromBody] TestEmailRequest request)
        {
            try
            {
                using (var client = new SmtpClient(request.Smtp.Host, request.Smtp.Port))
                {
                    client.Credentials = new NetworkCredential(request.Smtp.FromEmail, request.Smtp.Password);
                    client.EnableSsl = request.Smtp.EnableSsl;

                    var mailMessage = new MailMessage
                    {
                        From = new MailAddress(request.Smtp.FromEmail, request.Smtp.FromName),
                        Subject = "EduLearn - Thử nghiệm cấu hình SMTP",
                        Body = "<h1>Đây là email thử nghiệm</h1><p>Nếu bạn nhận được email này, cấu hình SMTP của bạn đã hoạt động chính xác!</p>",
                        IsBodyHtml = true
                    };

                    mailMessage.To.Add(request.ToEmail);
                    await client.SendMailAsync(mailMessage);
                }
                return Ok(new { message = "Email thử nghiệm đã được gửi thành công!" });
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = $"Lỗi khi gửi email: {ex.Message}" });
            }
        }

        public class TestEmailRequest
        {
            public SmtpSettings Smtp { get; set; }
            public string ToEmail { get; set; }
        }
    }
}
