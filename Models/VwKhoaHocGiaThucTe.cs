using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class VwKhoaHocGiaThucTe
{
    public int MaKhoaHoc { get; set; }

    public string TieuDe { get; set; } = null!;

    public decimal? GiaGoc { get; set; }

    public int? MaKhuyenMai { get; set; }

    public double? PhanTramGiam { get; set; }

    public DateTime? NgayKetThuc { get; set; }

    public double? GiaSauGiam { get; set; }
}
