using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace online_course_recommendation_system.Models;

public partial class BaiKiemTra
{
    [Key]
    public int MaBaiKiemTra { get; set; }
    public string TieuDe { get; set; } = null!;
    public string? MoTa { get; set; }
    public int? ThoiGianLamBai { get; set; } // minutes
    public int? MaChuong { get; set; }

    [System.ComponentModel.DataAnnotations.Schema.ForeignKey("MaChuong")]
    public virtual Chuong? MaChuongNavigation { get; set; }
    public virtual ICollection<CauHoi> CauHois { get; set; } = new List<CauHoi>();
    public virtual ICollection<KetQuaKiemTra> KetQuaKiemTras { get; set; } = new List<KetQuaKiemTra>();
}
