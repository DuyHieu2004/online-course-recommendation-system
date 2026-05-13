using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace online_course_recommendation_system.Models
{
    public class ThongBaoKhoaHoc
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int MaThongBao { get; set; }

        public int MaKhoaHoc { get; set; }

        [Required]
        [MaxLength(255)]
        public string TieuDe { get; set; } = null!;

        [Required]
        public string NoiDung { get; set; } = null!;

        public DateTime? NgayTao { get; set; }

        public virtual KhoaHoc? MaKhoaHocNavigation { get; set; }
    }
}
