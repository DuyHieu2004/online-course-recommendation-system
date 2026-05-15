using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class BaiHoc
{
    public int MaBaiHoc { get; set; }

    public string? LinkVideo { get; set; }

    public int? MaChuong { get; set; }

    public string? BaiTap { get; set; }

    public string? LyThuyet { get; set; }

    public string? LinkTaiLieu { get; set; }

    public virtual Chuong? MaChuongNavigation { get; set; }

    public virtual ICollection<TienDoBaiHoc> TienDoBaiHocs { get; set; } = new List<TienDoBaiHoc>();
}
