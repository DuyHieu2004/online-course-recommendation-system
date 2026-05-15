using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class KhoaHoc
{
    public int MaKhoaHoc { get; set; }

    public string TieuDe { get; set; } = null!;

    public string? TieuDePhu { get; set; }

    public string? MoTa { get; set; }

    public decimal? GiaGoc { get; set; }

    public string? TinhTrang { get; set; }

    public double? TbdanhGia { get; set; }

    public DateTime? NgayTao { get; set; }

    public DateTime? NgayCapNhat { get; set; }

    public int? MaTheLoai { get; set; }

    public string? KiNang { get; set; }

    public string? AnhUrl { get; set; }

    public int? MaKhuyenMai { get; set; }

    public int? ThoiGianHocDuKien { get; set; } // Tính bằng ngày

    public int? ThoiGianChoPhepTre { get; set; } // Tính bằng ngày
    public bool IsDeleted { get; set; }
    public string? TrinhDo { get; set; }

    public virtual ICollection<ChiTietGioHang> ChiTietGioHangs { get; set; } = new List<ChiTietGioHang>();

    public virtual ICollection<ChiTietHoaDon> ChiTietHoaDons { get; set; } = new List<ChiTietHoaDon>();

    public virtual ICollection<ChungChi> ChungChis { get; set; } = new List<ChungChi>();

    public virtual ICollection<Chuong> Chuongs { get; set; } = new List<Chuong>();

    public virtual ICollection<DanhGium> DanhGia { get; set; } = new List<DanhGium>();

    public virtual ICollection<GiangVienKhoaHoc> GiangVienKhoaHocs { get; set; } = new List<GiangVienKhoaHoc>();

    public virtual ICollection<LuotThichKhoaHoc> LuotThichKhoaHocs { get; set; } = new List<LuotThichKhoaHoc>();

    public virtual KhuyenMai? MaKhuyenMaiNavigation { get; set; }

    public virtual TheLoai? MaTheLoaiNavigation { get; set; }

    public virtual ICollection<TienDo> TienDos { get; set; } = new List<TienDo>();

    public virtual ICollection<ThongBaoKhoaHoc> ThongBaoKhoaHocs { get; set; } = new List<ThongBaoKhoaHoc>();
}
