using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class KhuyenMai
{
    public int MaKhuyenMai { get; set; }

    public string? TenChuongTrinh { get; set; }

    public double? PhanTramGiam { get; set; }

    public DateTime? NgayBatDau { get; set; }

    public DateTime? NgayKetThuc { get; set; }

    public virtual ICollection<KhoaHoc> KhoaHocs { get; set; } = new List<KhoaHoc>();
}
