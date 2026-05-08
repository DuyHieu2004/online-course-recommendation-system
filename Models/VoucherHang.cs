using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class VoucherHang
{
    public int MaVoucher { get; set; }

    public int MaHang { get; set; }

    public string MaCode { get; set; } = null!;

    public string? TieuDe { get; set; }

    public DateTime? NgayTao { get; set; }

    public virtual HangThanhVien MaHangNavigation { get; set; } = null!;
}
