namespace online_course_recommendation_system.Models
{
    public class SmtpSettings
    {
        public string Host { get; set; } = "smtp.gmail.com";
        public int Port { get; set; } = 587;
        public string FromName { get; set; } = "EduLearn";
        public string FromEmail { get; set; } = "noreply@edulearn.vn";
        public string Password { get; set; } = "";
        public bool EnableSsl { get; set; } = true;
    }

    public class EmailTemplate
    {
        public string Subject { get; set; } = "";
        public string Body { get; set; } = "";
    }

    public class GlobalSettings
    {
        public int DefaultGracePeriod { get; set; } = 7;
        public SmtpSettings Smtp { get; set; } = new SmtpSettings();
        public bool EnableExpiryNotification { get; set; } = true;
        public Dictionary<string, EmailTemplate> Templates { get; set; } = new();
    }
}
