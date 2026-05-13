namespace online_course_recommendation_system.DTO;

public class UserProfileDto
{
    public int MaNguoiDung { get; set; }
    public string Ten { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? VaiTro { get; set; }
    public string? LinkAnhDaiDien { get; set; }
    public string? TieuSu { get; set; }
    public string? TinhTrang { get; set; }
    public DateTime? NgayTao { get; set; }
    public string? HoSoBangCap { get; set; }
}
