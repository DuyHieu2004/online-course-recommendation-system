using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class ChungChi
{
    public int MaChungChi { get; set; }

    public DateTime? NgayPhat { get; set; }

    public int? MaKhoaHoc { get; set; }

    public int? MaNguoiDung { get; set; }

    public virtual KhoaHoc? MaKhoaHocNavigation { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
