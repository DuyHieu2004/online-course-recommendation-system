using System;
using System.ComponentModel.DataAnnotations;

namespace online_course_recommendation_system.Models;

public partial class LuaChon
{
    [Key]
    public int MaLuaChon { get; set; }
    public string NoiDung { get; set; } = null!;
    public bool LaDapAnDung { get; set; }
    public int? MaCauHoi { get; set; }

    [System.ComponentModel.DataAnnotations.Schema.ForeignKey("MaCauHoi")]
    public virtual CauHoi? MaCauHoiNavigation { get; set; }
}
