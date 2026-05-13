using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class Chuong
{
    public int MaChuong { get; set; }

    public string TieuDe { get; set; } = null!;

    public int? MaKhoaHoc { get; set; }

    public virtual ICollection<BaiHoc> BaiHocs { get; set; } = new List<BaiHoc>();

    public virtual KhoaHoc? MaKhoaHocNavigation { get; set; }

    public virtual ICollection<BaiKiemTra> BaiKiemTras { get; set; } = new List<BaiKiemTra>();
}
