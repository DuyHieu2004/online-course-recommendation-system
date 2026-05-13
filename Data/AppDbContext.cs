using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Models;

namespace online_course_recommendation_system.Data;

public partial class AppDbContext : DbContext
{
    public AppDbContext()
    {
    }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<BaiHoc> BaiHocs { get; set; }

    public virtual DbSet<ChiTietGioHang> ChiTietGioHangs { get; set; }

    public virtual DbSet<ChiTietHoaDon> ChiTietHoaDons { get; set; }

    public virtual DbSet<ChungChi> ChungChis { get; set; }

    public virtual DbSet<Chuong> Chuongs { get; set; }

    public virtual DbSet<DanhGium> DanhGia { get; set; }

    public virtual DbSet<GiangVienKhoaHoc> GiangVienKhoaHocs { get; set; }

    public virtual DbSet<GioHang> GioHangs { get; set; }

    public virtual DbSet<HoaDon> HoaDons { get; set; }

    public virtual DbSet<KhoaHoc> KhoaHocs { get; set; }

    public virtual DbSet<KhuyenMai> KhuyenMais { get; set; }

    public virtual DbSet<LuotThichKhoaHoc> LuotThichKhoaHocs { get; set; }

    public virtual DbSet<NguoiDung> NguoiDungs { get; set; }

    public virtual DbSet<TheLoai> TheLoais { get; set; }

    public virtual DbSet<TienDo> TienDos { get; set; }

    public virtual DbSet<TienDoBaiHoc> TienDoBaiHocs { get; set; }

    public virtual DbSet<VwKhoaHocGiaThucTe> VwKhoaHocGiaThucTes { get; set; }

    public virtual DbSet<ThongBao> ThongBaos { get; set; }
    public virtual DbSet<ThongBaoKhoaHoc> ThongBaoKhoaHocs { get; set; }

    public virtual DbSet<BaiKiemTra> BaiKiemTras { get; set; }
    public virtual DbSet<CauHoi> CauHois { get; set; }
    public virtual DbSet<LuaChon> LuaChons { get; set; }
    public virtual DbSet<KetQuaKiemTra> KetQuaKiemTras { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<BaiHoc>(entity =>
        {
            entity.HasKey(e => e.MaBaiHoc).HasName("PK__BaiHoc__3F6433C2423002E4");

            entity.ToTable("BaiHoc");

            entity.Property(e => e.LinkVideo).IsUnicode(false);

            entity.HasOne(d => d.MaChuongNavigation).WithMany(p => p.BaiHocs)
                .HasForeignKey(d => d.MaChuong)
                .HasConstraintName("FK__BaiHoc__MaChuong__68487DD7");
        });

        modelBuilder.Entity<ChiTietGioHang>(entity =>
        {
            entity.HasKey(e => e.MaChiTietGioHang).HasName("PK__ChiTietG__BBF474985C33E8EA");

            entity.ToTable("ChiTietGioHang", tb => tb.HasTrigger("trg_ChanMuaLaiKhoaHoc"));

            entity.HasIndex(e => new { e.MaGioHang, e.MaKhoaHoc }, "UQ_GioHang_KhoaHoc").IsUnique();

            entity.Property(e => e.Gia).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaGioHangNavigation).WithMany(p => p.ChiTietGioHangs)
                .HasForeignKey(d => d.MaGioHang)
                .HasConstraintName("FK__ChiTietGi__MaGio__693CA210");

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.ChiTietGioHangs)
                .HasForeignKey(d => d.MaKhoaHoc)
                .HasConstraintName("FK__ChiTietGi__MaKho__6A30C649");
        });

        modelBuilder.Entity<ChiTietHoaDon>(entity =>
        {
            entity.HasKey(e => e.MaChiTietHoaDon).HasName("PK__ChiTietH__CFF2C42679E68DF4");

            entity.ToTable("ChiTietHoaDon", tb => tb.HasTrigger("trg_CapNhatTongTienHoaDon"));

            entity.Property(e => e.Gia).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaHoaDonNavigation).WithMany(p => p.ChiTietHoaDons)
                .HasForeignKey(d => d.MaHoaDon)
                .HasConstraintName("FK__ChiTietHo__MaHoa__6B24EA82");

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.ChiTietHoaDons)
                .HasForeignKey(d => d.MaKhoaHoc)
                .HasConstraintName("FK__ChiTietHo__MaKho__6C190EBB");
        });

        modelBuilder.Entity<ChungChi>(entity =>
        {
            entity.HasKey(e => e.MaChungChi).HasName("PK__ChungChi__BD2C8F392CC67813");

            entity.ToTable("ChungChi");

            entity.Property(e => e.NgayPhat)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.ChungChis)
                .HasForeignKey(d => d.MaKhoaHoc)
                .HasConstraintName("FK__ChungChi__MaKhoa__6D0D32F4");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.ChungChis)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__ChungChi__MaNguo__6E01572D");
        });

        modelBuilder.Entity<Chuong>(entity =>
        {
            entity.HasKey(e => e.MaChuong).HasName("PK__Chuong__0D6A804C09D33111");

            entity.ToTable("Chuong");

            entity.Property(e => e.TieuDe).HasMaxLength(255);

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.Chuongs)
                .HasForeignKey(d => d.MaKhoaHoc)
                .HasConstraintName("FK__Chuong__MaKhoaHo__6EF57B66");
        });

        modelBuilder.Entity<DanhGium>(entity =>
        {
            entity.HasKey(e => e.MaDanhGia).HasName("PK__DanhGia__AA9515BF66EB22E9");

            entity.ToTable(tb =>
                {
                    tb.HasTrigger("trg_GioiHanDanhGia");
                    tb.HasTrigger("trg_KiemTraDieuKienDanhGia");
                });

            entity.Property(e => e.NgayDanhGia)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Thich).HasDefaultValue(0);

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.DanhGia)
                .HasForeignKey(d => d.MaKhoaHoc)
                .HasConstraintName("FK__DanhGia__MaKhoaH__6FE99F9F");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.DanhGia)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__DanhGia__MaNguoi__70DDC3D8");
        });

        modelBuilder.Entity<GiangVienKhoaHoc>(entity =>
        {
            entity.HasKey(e => new { e.MaKhoaHoc, e.MaGiangVien }).HasName("PK__GiangVie__F4F341734E844ABB");

            entity.ToTable("GiangVien_KhoaHoc");

            entity.Property(e => e.LaGiangVienChinh).HasDefaultValue(false);
            entity.Property(e => e.TyLeDoanhThu).HasDefaultValue(0.0);

            entity.HasOne(d => d.MaGiangVienNavigation).WithMany(p => p.GiangVienKhoaHocs)
                .HasForeignKey(d => d.MaGiangVien)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__GiangVien__MaGia__71D1E811");

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.GiangVienKhoaHocs)
                .HasForeignKey(d => d.MaKhoaHoc)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__GiangVien__MaKho__72C60C4A");
        });

        modelBuilder.Entity<GioHang>(entity =>
        {
            entity.HasKey(e => e.MaGioHang).HasName("PK__GioHang__F5001DA31990B81C");

            entity.ToTable("GioHang");

            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.GioHangs)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__GioHang__MaNguoi__73BA3083");
        });

        modelBuilder.Entity<HoaDon>(entity =>
        {
            entity.HasKey(e => e.MaHoaDon).HasName("PK__HoaDon__835ED13B50CA0A6B");

            entity.ToTable("HoaDon");

            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.PhuongThucThanhToan).HasMaxLength(100);
            entity.Property(e => e.TinhTrangThanhToan).HasDefaultValue(false);
            entity.Property(e => e.TongTien).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.HoaDons)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__HoaDon__MaNguoiD__74AE54BC");
        });

        modelBuilder.Entity<KhoaHoc>(entity =>
        {
            entity.HasKey(e => e.MaKhoaHoc).HasName("PK__KhoaHoc__48F0FF989E7D9F70");

            entity.ToTable("KhoaHoc", tb => tb.HasTrigger("trg_ChanPublishKhoaHoc"));

            entity.Property(e => e.AnhUrl)
                .IsUnicode(false)
                .HasColumnName("AnhURL");
            entity.Property(e => e.GiaGoc).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.NgayCapNhat).HasColumnType("datetime");
            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.TbdanhGia)
                .HasDefaultValue(0.0)
                .HasColumnName("TBDanhGia");
            entity.Property(e => e.TieuDe).HasMaxLength(255);
            entity.Property(e => e.TieuDePhu).HasMaxLength(255);
            entity.Property(e => e.TinhTrang).HasMaxLength(50);

            entity.HasOne(d => d.MaKhuyenMaiNavigation).WithMany(p => p.KhoaHocs)
                .HasForeignKey(d => d.MaKhuyenMai)
                .HasConstraintName("FK__KhoaHoc__MaKhuye__75A278F5");

            entity.HasOne(d => d.MaTheLoaiNavigation).WithMany(p => p.KhoaHocs)
                .HasForeignKey(d => d.MaTheLoai)
                .HasConstraintName("FK__KhoaHoc__MaTheLo__76969D2E");
        });

        modelBuilder.Entity<KhuyenMai>(entity =>
        {
            entity.HasKey(e => e.MaKhuyenMai).HasName("PK__KhuyenMa__6F56B3BDFEC9B3B5");

            entity.ToTable("KhuyenMai");

            entity.Property(e => e.NgayBatDau).HasColumnType("datetime");
            entity.Property(e => e.NgayKetThuc).HasColumnType("datetime");
            entity.Property(e => e.TenChuongTrinh).HasMaxLength(200);
        });

        modelBuilder.Entity<LuotThichKhoaHoc>(entity =>
        {
            entity.HasKey(e => e.MaLuotThich).HasName("PK__LuotThic__CF7B01A463AC6384");

            entity.ToTable("LuotThichKhoaHoc");

            entity.HasIndex(e => new { e.MaNguoiDung, e.MaKhoaHoc }, "UQ_LuotThichKhoaHoc").IsUnique();

            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.LuotThichKhoaHocs)
                .HasForeignKey(d => d.MaKhoaHoc)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__LuotThich__MaKho__778AC167");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.LuotThichKhoaHocs)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__LuotThich__MaNgu__787EE5A0");
        });

        modelBuilder.Entity<NguoiDung>(entity =>
        {
            entity.HasKey(e => e.MaNguoiDung).HasName("PK__NguoiDun__C539D762A6FF944D");

            entity.ToTable("NguoiDung");

            entity.HasIndex(e => e.Email, "UQ__NguoiDun__A9D105343A620203").IsUnique();

            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.LinkAnhDaiDien).IsUnicode(false);
            entity.Property(e => e.MatKhau)
                .HasMaxLength(255)
                .IsUnicode(false);
            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Ten).HasMaxLength(100);
            entity.Property(e => e.TinhTrang).HasMaxLength(50);
            entity.Property(e => e.VaiTro).HasMaxLength(20);
        });

        modelBuilder.Entity<TheLoai>(entity =>
        {
            entity.HasKey(e => e.MaTheLoai).HasName("PK__TheLoai__D73FF34A9CEBC168");

            entity.ToTable("TheLoai");

            entity.Property(e => e.Ten).HasMaxLength(100);
        });

        modelBuilder.Entity<TienDo>(entity =>
        {
            entity.HasKey(e => e.MaTienDo).HasName("PK__TienDo__C5D04CAEAAF35E0B");

            entity.ToTable("TienDo");

            entity.Property(e => e.NgayThamGia)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.NgayKetThuc).HasColumnType("datetime");
            entity.Property(e => e.PhanTramTienDo).HasDefaultValue(0.0);
            entity.Property(e => e.TinhTrang).HasDefaultValue(false);

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.TienDos)
                .HasForeignKey(d => d.MaKhoaHoc)
                .HasConstraintName("FK__TienDo__MaKhoaHo__797309D9");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.TienDos)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__TienDo__MaNguoiD__7A672E12");
        });

        modelBuilder.Entity<ThongBao>(entity =>
        {
            entity.HasKey(e => e.MaThongBao).HasName("PK_ThongBao");

            entity.ToTable("ThongBao");

            entity.Property(e => e.TieuDe).HasMaxLength(255);
            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DaDoc).HasDefaultValue(false);

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.ThongBaos)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK_ThongBao_NguoiDung");
        });

        modelBuilder.Entity<TienDoBaiHoc>(entity =>
        {
            entity.HasKey(e => e.MaTienDoBaiHoc).HasName("PK__TienDoBa__299D1CC6A43709F1");

            entity.ToTable("TienDoBaiHoc");

            entity.Property(e => e.DaHoanThanh).HasDefaultValue(false);
            entity.Property(e => e.LanCuoiXem).HasColumnType("datetime");

            entity.HasOne(d => d.MaBaiHocNavigation).WithMany(p => p.TienDoBaiHocs)
                .HasForeignKey(d => d.MaBaiHoc)
                .HasConstraintName("FK__TienDoBai__MaBai__7B5B524B");

            entity.HasOne(d => d.MaTienDoNavigation).WithMany(p => p.TienDoBaiHocs)
                .HasForeignKey(d => d.MaTienDo)
                .HasConstraintName("FK__TienDoBai__MaTie__7C4F7684");
        });

        modelBuilder.Entity<ThongBaoKhoaHoc>(entity =>
        {
            entity.HasKey(e => e.MaThongBao).HasName("PK_ThongBaoKhoaHoc");

            entity.ToTable("ThongBaoKhoaHoc");

            entity.Property(e => e.TieuDe).HasMaxLength(255);
            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaKhoaHocNavigation).WithMany(p => p.ThongBaoKhoaHocs)
                .HasForeignKey(d => d.MaKhoaHoc)
                .HasConstraintName("FK_ThongBaoKhoaHoc_KhoaHoc");
        });

        modelBuilder.Entity<VwKhoaHocGiaThucTe>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("vw_KhoaHoc_GiaThucTe");

            entity.Property(e => e.GiaGoc).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.NgayKetThuc).HasColumnType("datetime");
            entity.Property(e => e.TieuDe).HasMaxLength(255);
        });

        modelBuilder.Entity<BaiKiemTra>(entity => { entity.ToTable("BaiKiemTra"); });
        modelBuilder.Entity<CauHoi>(entity => { entity.ToTable("CauHoi"); });
        modelBuilder.Entity<LuaChon>(entity => { entity.ToTable("LuaChon"); });
        modelBuilder.Entity<KetQuaKiemTra>(entity => { entity.ToTable("KetQuaKiemTra"); });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
