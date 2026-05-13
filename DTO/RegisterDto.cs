namespace online_course_recommendation_system.DTO;
    using Microsoft.AspNetCore.Http; // For IFormFile

    public class RegisterDto
    {
        public string Ten { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string MatKhau { get; set; } = string.Empty;
        public string? VaiTro { get; set; }
        public IFormFile? File { get; set; }
    }