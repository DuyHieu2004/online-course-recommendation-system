using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class ChiTietHoaDon
{
    public int MaChiTietHoaDon { get; set; }

    public decimal? Gia { get; set; }

    public int? MaHoaDon { get; set; }

    public int? MaKhoaHoc { get; set; }

    public virtual HoaDon? MaHoaDonNavigation { get; set; }

    public virtual KhoaHoc? MaKhoaHocNavigation { get; set; }
}
