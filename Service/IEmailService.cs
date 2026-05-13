using System.Collections.Generic;
using System.Threading.Tasks;

namespace online_course_recommendation_system.Service
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string body);
        string ReplacePlaceholders(string template, Dictionary<string, string> placeholders);
    }
}
