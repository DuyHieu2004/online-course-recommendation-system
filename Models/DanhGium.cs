using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class DanhGium
{
    public int MaDanhGia { get; set; }

    public double? Rating { get; set; }

    public string? BinhLuan { get; set; }

    public DateTime? NgayDanhGia { get; set; }

    public int? Thich { get; set; }

    public int? MaKhoaHoc { get; set; }

    public int? MaNguoiDung { get; set; }

    public virtual KhoaHoc? MaKhoaHocNavigation { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
