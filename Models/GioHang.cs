using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class GioHang
{
    public int MaGioHang { get; set; }

    public DateTime? NgayTao { get; set; }

    public int? MaNguoiDung { get; set; }

    public virtual ICollection<ChiTietGioHang> ChiTietGioHangs { get; set; } = new List<ChiTietGioHang>();

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
