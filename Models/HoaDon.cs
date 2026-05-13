using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class HoaDon
{
    public int MaHoaDon { get; set; }

    public decimal TongTien { get; set; }

    public string? PhuongThucThanhToan { get; set; }

    public bool? TinhTrangThanhToan { get; set; }

    public DateTime? NgayTao { get; set; }

    public int? MaNguoiDung { get; set; }

    public virtual ICollection<ChiTietHoaDon> ChiTietHoaDons { get; set; } = new List<ChiTietHoaDon>();

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
