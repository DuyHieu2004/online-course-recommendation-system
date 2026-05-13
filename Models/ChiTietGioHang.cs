using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class ChiTietGioHang
{
    public int MaChiTietGioHang { get; set; }

    public decimal? Gia { get; set; }

    public int? MaKhoaHoc { get; set; }

    public int? MaGioHang { get; set; }

    public virtual GioHang? MaGioHangNavigation { get; set; }

    public virtual KhoaHoc? MaKhoaHocNavigation { get; set; }
}
