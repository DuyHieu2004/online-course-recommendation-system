using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class ThongBao
{
    public int MaThongBao { get; set; }

    public int MaNguoiDung { get; set; }

    public string TieuDe { get; set; } = null!;

    public string NoiDung { get; set; } = null!;

    public DateTime NgayTao { get; set; }

    public bool DaDoc { get; set; }

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;
}
