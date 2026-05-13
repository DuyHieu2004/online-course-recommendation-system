namespace online_course_recommendation_system.DTO;

public class PromotionDto
{
    public string? TenChuongTrinh { get; set; }
    public double? PhanTramGiam { get; set; }
    public DateTime? NgayBatDau { get; set; }
    public DateTime? NgayKetThuc { get; set; }

    public List<int> CourseIds { get; set; } = new List<int>();
    public List<int> CategoryIds { get; set; } = new List<int>();
}
