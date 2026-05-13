using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class GiangVienKhoaHoc
{
    public int MaKhoaHoc { get; set; }

    public int MaGiangVien { get; set; }

    public bool? LaGiangVienChinh { get; set; }

    public double? TyLeDoanhThu { get; set; }

    public virtual NguoiDung MaGiangVienNavigation { get; set; } = null!;

    public virtual KhoaHoc MaKhoaHocNavigation { get; set; } = null!;
}
