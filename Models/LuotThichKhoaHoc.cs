using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class LuotThichKhoaHoc
{
    public int MaLuotThich { get; set; }

    public int MaNguoiDung { get; set; }

    public int MaKhoaHoc { get; set; }

    public DateTime? NgayTao { get; set; }

    public virtual KhoaHoc MaKhoaHocNavigation { get; set; } = null!;

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;
}
