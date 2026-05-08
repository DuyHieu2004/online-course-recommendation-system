using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class HangThanhVien
{
    public int MaHang { get; set; }

    public string TenHang { get; set; } = null!;

    public int SoKhoaHocToiThieu { get; set; }

    public double PhanTramUuDai { get; set; }

    public virtual ICollection<VoucherHang> VoucherHangs { get; set; } = new List<VoucherHang>();
}
