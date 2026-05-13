using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;
using Microsoft.EntityFrameworkCore;
using System.IO;
using System.Text.Json;
using System.Collections.Generic;

namespace online_course_recommendation_system.Service
{
    public class DeadlineReminderWorker : BackgroundService
    {
        private readonly ILogger<DeadlineReminderWorker> _logger;
        private readonly IServiceProvider _serviceProvider;

        public DeadlineReminderWorker(ILogger<DeadlineReminderWorker> logger, IServiceProvider serviceProvider)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("DeadlineReminderWorker đang chạy.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckDeadlinesAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi xảy ra trong DeadlineReminderWorker.");
                }

                await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
            }
        }

        private async Task CheckDeadlinesAsync()
        {
            using (var scope = _serviceProvider.CreateScope())
            {
                var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();

                var now = DateTime.Now;
                
                // Load settings
                var settingsPath = Path.Combine(Directory.GetCurrentDirectory(), "systemsettings.json");
                GlobalSettings? settings = null;
                if (File.Exists(settingsPath))
                {
                    var json = await File.ReadAllTextAsync(settingsPath);
                    settings = JsonSerializer.Deserialize<GlobalSettings>(json, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                }

                int gracePeriod = settings?.DefaultGracePeriod ?? 7;

                var activeTienDos = await context.TienDos
                    .Include(t => t.MaKhoaHocNavigation)
                    .Include(t => t.MaNguoiDungNavigation)
                    .Where(t => t.NgayKetThuc.HasValue && t.PhanTramTienDo < 100)
                    .ToListAsync();

                foreach (var tienDo in activeTienDos)
                {
                    var finalDeadline = tienDo.NgayKetThuc.Value;
                    var studyDeadline = finalDeadline.AddDays(-gracePeriod);

                    string typeKey = "";
                    if (now >= studyDeadline.AddDays(-3) && now < studyDeadline) typeKey = "Sắp hết hạn";
                    else if (now >= studyDeadline && now < finalDeadline) typeKey = "Quá hạn khóa học"; // Matches label in UI
                    else if (now >= finalDeadline && now < finalDeadline.AddDays(1)) typeKey = "Quá hạn hoàn toàn";

                    if (string.IsNullOrEmpty(typeKey)) continue;

                    // Fetch template or use fallback
                    EmailTemplate template = new EmailTemplate();
                    if (settings?.Templates != null && settings.Templates.TryGetValue(typeKey, out var found))
                    {
                        template = found;
                    }
                    else
                    {
                        template.Subject = $"Thông báo: {typeKey}";
                        template.Body = $"Chào {{{{userName}}}}, khóa học {{{{courseName}}}} của bạn {typeKey.ToLower()}. Hạn cuối là {{{{deadline}}}}.";
                    }

                    var placeholders = new Dictionary<string, string>
                    {
                        { "userName", tienDo.MaNguoiDungNavigation?.Ten ?? "Người dùng" },
                        { "courseName", tienDo.MaKhoaHocNavigation?.TieuDe ?? "Khóa học" },
                        { "deadline", finalDeadline.ToString("dd/MM/yyyy") },
                        { "link", "https://edulearn.vn/my-courses" }
                    };

                    string subject = emailService.ReplacePlaceholders(template.Subject, placeholders);
                    string body = emailService.ReplacePlaceholders(template.Body, placeholders);

                    // Check recent notification
                    var recentNotif = await context.ThongBaos
                        .AnyAsync(tb => tb.MaNguoiDung == tienDo.MaNguoiDung &&
                                        tb.TieuDe == subject &&
                                        tb.NgayTao >= now.AddDays(-2));

                    if (!recentNotif)
                    {
                        context.ThongBaos.Add(new ThongBao
                        {
                            MaNguoiDung = tienDo.MaNguoiDung ?? 0,
                            TieuDe = subject,
                            NoiDung = body,
                            NgayTao = DateTime.Now,
                            DaDoc = false
                        });

                        if (!string.IsNullOrEmpty(tienDo.MaNguoiDungNavigation?.Email))
                        {
                            try {
                                await emailService.SendEmailAsync(tienDo.MaNguoiDungNavigation.Email, subject, body);
                            } catch (Exception ex) {
                                _logger.LogError(ex, $"Lỗi gửi email tới {tienDo.MaNguoiDungNavigation.Email}");
                            }
                        }
                    }
                }

                await context.SaveChangesAsync();
            }
        }
    }
}
