using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class NguoiDung
{
    public int MaNguoiDung { get; set; }

    public string Ten { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string MatKhau { get; set; } = null!;

    public string? VaiTro { get; set; }

    public string? LinkAnhDaiDien { get; set; }

    public string? TieuSu { get; set; }

    public string? TinhTrang { get; set; }

    public DateTime? NgayTao { get; set; }

    public string? HoSoBangCap { get; set; }

    public virtual ICollection<ChungChi> ChungChis { get; set; } = new List<ChungChi>();

    public virtual ICollection<DanhGium> DanhGia { get; set; } = new List<DanhGium>();

    public virtual ICollection<GiangVienKhoaHoc> GiangVienKhoaHocs { get; set; } = new List<GiangVienKhoaHoc>();

    public virtual ICollection<GioHang> GioHangs { get; set; } = new List<GioHang>();

    public virtual ICollection<HoaDon> HoaDons { get; set; } = new List<HoaDon>();

    public virtual ICollection<LuotThichKhoaHoc> LuotThichKhoaHocs { get; set; } = new List<LuotThichKhoaHoc>();

    public virtual ICollection<TienDo> TienDos { get; set; } = new List<TienDo>();

    public virtual ICollection<ThongBao> ThongBaos { get; set; } = new List<ThongBao>();
}
