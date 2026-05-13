using System;
using System.ComponentModel.DataAnnotations;

namespace online_course_recommendation_system.Models;

public partial class KetQuaKiemTra
{
    [Key]
    public int MaKetQua { get; set; }
    public int? MaNguoiDung { get; set; }
    public int? MaBaiKiemTra { get; set; }
    public double DiemSo { get; set; }
    public DateTime? NgayNopBai { get; set; }

    [System.ComponentModel.DataAnnotations.Schema.ForeignKey("MaNguoiDung")]
    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
    
    [System.ComponentModel.DataAnnotations.Schema.ForeignKey("MaBaiKiemTra")]
    public virtual BaiKiemTra? MaBaiKiemTraNavigation { get; set; }
}
