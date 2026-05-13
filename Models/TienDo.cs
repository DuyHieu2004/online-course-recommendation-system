using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class TienDo
{
    public int MaTienDo { get; set; }

    public DateTime? NgayThamGia { get; set; }

    public double? PhanTramTienDo { get; set; }

    public bool? TinhTrang { get; set; }

    public int? MaKhoaHoc { get; set; }

    public int? MaNguoiDung { get; set; }

    public DateTime? NgayKetThuc { get; set; }

    public virtual KhoaHoc? MaKhoaHocNavigation { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }

    public virtual ICollection<TienDoBaiHoc> TienDoBaiHocs { get; set; } = new List<TienDoBaiHoc>();
}
