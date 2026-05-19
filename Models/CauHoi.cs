using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace online_course_recommendation_system.Models;

public partial class CauHoi
{
    [Key]
    public int MaCauHoi { get; set; }
    public string NoiDung { get; set; } = null!;
    public double Diem { get; set; }
    public int? MaBaiKiemTra { get; set; }

    [System.ComponentModel.DataAnnotations.Schema.ForeignKey("MaBaiKiemTra")]
    public virtual BaiKiemTra? MaBaiKiemTraNavigation { get; set; }
    public virtual ICollection<LuaChon> LuaChons { get; set; } = new List<LuaChon>();
}
