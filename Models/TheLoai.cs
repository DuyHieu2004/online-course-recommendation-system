using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class TheLoai
{
    public int MaTheLoai { get; set; }

    public string Ten { get; set; } = null!;

    public string? MoTa { get; set; }

    public virtual ICollection<KhoaHoc> KhoaHocs { get; set; } = new List<KhoaHoc>();
}
