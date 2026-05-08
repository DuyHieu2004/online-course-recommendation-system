using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;
using online_course_recommendation_system.Models;
using Microsoft.Extensions.Options;
using System.Collections.Generic;

namespace online_course_recommendation_system.Service
{
    public class EmailService : IEmailService
    {
        private readonly SmtpSettings _settings;

        public EmailService(IOptions<SmtpSettings> settings)
        {
            _settings = settings.Value;
        }

        public async Task SendEmailAsync(string toEmail, string subject, string body)
        {
            if (string.IsNullOrEmpty(_settings.Password) || string.IsNullOrEmpty(_settings.FromEmail))
                return;

            using (var client = new SmtpClient(_settings.Host, _settings.Port))
            {
                client.Credentials = new NetworkCredential(_settings.FromEmail, _settings.Password);
                client.EnableSsl = _settings.EnableSsl;

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(_settings.FromEmail, _settings.FromName),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };

                mailMessage.To.Add(toEmail);

                await client.SendMailAsync(mailMessage);
            }
        }

        public string ReplacePlaceholders(string template, Dictionary<string, string> placeholders)
        {
            if (string.IsNullOrEmpty(template)) return "";
            foreach (var item in placeholders)
            {
                template = template.Replace("{{" + item.Key + "}}", item.Value);
            }
            return template;
        }
    }
}
