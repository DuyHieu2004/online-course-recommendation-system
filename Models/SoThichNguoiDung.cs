using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class SoThichNguoiDung
{
    public int MaSoThich { get; set; }

    public int MaNguoiDung { get; set; }

    public int MaTheLoai { get; set; }

    public DateTime? NgayTao { get; set; }

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;

    public virtual TheLoai MaTheLoaiNavigation { get; set; } = null!;
}
