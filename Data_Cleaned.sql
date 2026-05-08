USE [ELearning_DB]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_TinhThuNhapGiaoVien]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_TinhThuNhapGiaoVien] (@MaGiaoVien INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongThuNhap DECIMAL(18,2);
    SELECT @TongThuNhap = SUM(ct.Gia * (gvk.TyLeDoanhThu / 100.0))
    FROM ChiTietHoaDon ct
    JOIN GiangVien_KhoaHoc gvk ON ct.MaKhoaHoc = gvk.MaKhoaHoc
    WHERE gvk.MaGiangVien = @MaGiaoVien;
    RETURN ISNULL(@TongThuNhap, 0);
END;
GO
/****** Object:  Table [dbo].[KhuyenMai]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KhuyenMai](
	[MaKhuyenMai] [int] IDENTITY(1,1) NOT NULL,
	[TenChuongTrinh] [nvarchar](200) NULL,
	[PhanTramGiam] [float] NULL,
	[NgayBatDau] [datetime] NULL,
	[NgayKetThuc] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaKhuyenMai] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[KhoaHoc]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KhoaHoc](
	[MaKhoaHoc] [int] IDENTITY(1,1) NOT NULL,
	[TieuDe] [nvarchar](255) NOT NULL,
	[TieuDePhu] [nvarchar](255) NULL,
	[MoTa] [nvarchar](max) NULL,
	[GiaGoc] [decimal](18, 2) NULL,
	[TinhTrang] [nvarchar](50) NULL,
	[TBDanhGia] [float] NULL,
	[NgayTao] [datetime] NULL,
	[NgayCapNhat] [datetime] NULL,
	[MaTheLoai] [int] NULL,
	[KiNang] [nvarchar](max) NULL,
	[AnhURL] [varchar](max) NULL,
	[MaKhuyenMai] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaKhoaHoc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_KhoaHoc_GiaThucTe]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Logic Khuyến mãi (Hết date, Mapping, Tính giá sau giảm)
CREATE VIEW [dbo].[vw_KhoaHoc_GiaThucTe] AS
SELECT 
    kh.MaKhoaHoc, kh.TieuDe, kh.GiaGoc,
    km.MaKhuyenMai, km.PhanTramGiam, km.NgayKetThuc,
    CASE 
        WHEN km.MaKhuyenMai IS NOT NULL AND km.NgayKetThuc >= GETDATE() THEN kh.GiaGoc * (1.0 - (km.PhanTramGiam / 100.0))
        ELSE kh.GiaGoc 
    END AS GiaSauGiam
FROM KhoaHoc kh
LEFT JOIN KhuyenMai km ON kh.MaKhuyenMai = km.MaKhuyenMai;
GO
/****** Object:  Table [dbo].[BaiHoc]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BaiHoc](
	[MaBaiHoc] [int] IDENTITY(1,1) NOT NULL,
	[LinkVideo] [varchar](max) NULL,
	[MaChuong] [int] NULL,
	[BaiTap] [nvarchar](max) NULL,
	[LyThuyet] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaBaiHoc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ChiTietGioHang]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChiTietGioHang](
	[MaChiTietGioHang] [int] IDENTITY(1,1) NOT NULL,
	[Gia] [decimal](18, 2) NULL,
	[MaKhoaHoc] [int] NULL,
	[MaGioHang] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaChiTietGioHang] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_GioHang_KhoaHoc] UNIQUE NONCLUSTERED 
(
	[MaGioHang] ASC,
	[MaKhoaHoc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ChiTietHoaDon]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChiTietHoaDon](
	[MaChiTietHoaDon] [int] IDENTITY(1,1) NOT NULL,
	[Gia] [decimal](18, 2) NULL,
	[MaHoaDon] [int] NULL,
	[MaKhoaHoc] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaChiTietHoaDon] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ChungChi]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChungChi](
	[MaChungChi] [int] IDENTITY(1,1) NOT NULL,
	[NgayPhat] [datetime] NULL,
	[MaKhoaHoc] [int] NULL,
	[MaNguoiDung] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaChungChi] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Chuong]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Chuong](
	[MaChuong] [int] IDENTITY(1,1) NOT NULL,
	[TieuDe] [nvarchar](255) NOT NULL,
	[MaKhoaHoc] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaChuong] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DanhGia]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DanhGia](
	[MaDanhGia] [int] IDENTITY(1,1) NOT NULL,
	[Rating] [float] NULL,
	[BinhLuan] [nvarchar](max) NULL,
	[NgayDanhGia] [datetime] NULL,
	[Thich] [int] NULL,
	[MaKhoaHoc] [int] NULL,
	[MaNguoiDung] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaDanhGia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GiangVien_KhoaHoc]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GiangVien_KhoaHoc](
	[MaKhoaHoc] [int] NOT NULL,
	[MaGiangVien] [int] NOT NULL,
	[LaGiangVienChinh] [bit] NULL,
	[TyLeDoanhThu] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaKhoaHoc] ASC,
	[MaGiangVien] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GioHang]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GioHang](
	[MaGioHang] [int] IDENTITY(1,1) NOT NULL,
	[NgayTao] [datetime] NULL,
	[MaNguoiDung] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaGioHang] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HoaDon]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HoaDon](
	[MaHoaDon] [int] IDENTITY(1,1) NOT NULL,
	[TongTien] [decimal](18, 2) NOT NULL,
	[PhuongThucThanhToan] [nvarchar](100) NULL,
	[TinhTrangThanhToan] [bit] NULL,
	[NgayTao] [datetime] NULL,
	[MaNguoiDung] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaHoaDon] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LuotThichKhoaHoc]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LuotThichKhoaHoc](
	[MaLuotThich] [int] IDENTITY(1,1) NOT NULL,
	[MaNguoiDung] [int] NOT NULL,
	[MaKhoaHoc] [int] NOT NULL,
	[NgayTao] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaLuotThich] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_LuotThichKhoaHoc] UNIQUE NONCLUSTERED 
(
	[MaNguoiDung] ASC,
	[MaKhoaHoc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NguoiDung]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NguoiDung](
	[MaNguoiDung] [int] IDENTITY(1,1) NOT NULL,
	[Ten] [nvarchar](100) NOT NULL,
	[Email] [varchar](100) NOT NULL,
	[MatKhau] [varchar](255) NOT NULL,
	[VaiTro] [nvarchar](20) NULL,
	[LinkAnhDaiDien] [varchar](max) NULL,
	[TieuSu] [nvarchar](max) NULL,
	[TinhTrang] [nvarchar](50) NULL,
	[NgayTao] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaNguoiDung] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TheLoai]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TheLoai](
	[MaTheLoai] [int] IDENTITY(1,1) NOT NULL,
	[Ten] [nvarchar](100) NOT NULL,
	[MoTa] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaTheLoai] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TienDo]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TienDo](
	[MaTienDo] [int] IDENTITY(1,1) NOT NULL,
	[NgayThamGia] [datetime] NULL,
	[PhanTramTienDo] [float] NULL,
	[TinhTrang] [bit] NULL,
	[MaKhoaHoc] [int] NULL,
	[MaNguoiDung] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaTienDo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TienDoBaiHoc]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TienDoBaiHoc](
	[MaTienDoBaiHoc] [int] IDENTITY(1,1) NOT NULL,
	[MaBaiHoc] [int] NULL,
	[DaHoanThanh] [bit] NULL,
	[LanCuoiXem] [datetime] NULL,
	[ThoiGian] [int] NULL,
	[MaTienDo] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaTienDoBaiHoc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ChungChi] ADD  DEFAULT (getdate()) FOR [NgayPhat]
GO
ALTER TABLE [dbo].[DanhGia] ADD  DEFAULT (getdate()) FOR [NgayDanhGia]
GO
ALTER TABLE [dbo].[DanhGia] ADD  DEFAULT ((0)) FOR [Thich]
GO
ALTER TABLE [dbo].[GiangVien_KhoaHoc] ADD  DEFAULT ((0)) FOR [LaGiangVienChinh]
GO
ALTER TABLE [dbo].[GiangVien_KhoaHoc] ADD  DEFAULT ((0)) FOR [TyLeDoanhThu]
GO
ALTER TABLE [dbo].[GioHang] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[HoaDon] ADD  DEFAULT ((0)) FOR [TinhTrangThanhToan]
GO
ALTER TABLE [dbo].[HoaDon] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[KhoaHoc] ADD  DEFAULT ((0)) FOR [TBDanhGia]
GO
ALTER TABLE [dbo].[KhoaHoc] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[LuotThichKhoaHoc] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[NguoiDung] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[TienDo] ADD  DEFAULT (getdate()) FOR [NgayThamGia]
GO
ALTER TABLE [dbo].[TienDo] ADD  DEFAULT ((0)) FOR [PhanTramTienDo]
GO
ALTER TABLE [dbo].[TienDo] ADD  DEFAULT ((0)) FOR [TinhTrang]
GO
ALTER TABLE [dbo].[TienDoBaiHoc] ADD  DEFAULT ((0)) FOR [DaHoanThanh]
GO
ALTER TABLE [dbo].[BaiHoc]  WITH CHECK ADD FOREIGN KEY([MaChuong])
REFERENCES [dbo].[Chuong] ([MaChuong])
GO
ALTER TABLE [dbo].[ChiTietGioHang]  WITH CHECK ADD FOREIGN KEY([MaGioHang])
REFERENCES [dbo].[GioHang] ([MaGioHang])
GO
ALTER TABLE [dbo].[ChiTietGioHang]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[ChiTietHoaDon]  WITH CHECK ADD FOREIGN KEY([MaHoaDon])
REFERENCES [dbo].[HoaDon] ([MaHoaDon])
GO
ALTER TABLE [dbo].[ChiTietHoaDon]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[ChungChi]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[ChungChi]  WITH CHECK ADD FOREIGN KEY([MaNguoiDung])
REFERENCES [dbo].[NguoiDung] ([MaNguoiDung])
GO
ALTER TABLE [dbo].[Chuong]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[DanhGia]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[DanhGia]  WITH CHECK ADD FOREIGN KEY([MaNguoiDung])
REFERENCES [dbo].[NguoiDung] ([MaNguoiDung])
GO
ALTER TABLE [dbo].[GiangVien_KhoaHoc]  WITH CHECK ADD FOREIGN KEY([MaGiangVien])
REFERENCES [dbo].[NguoiDung] ([MaNguoiDung])
GO
ALTER TABLE [dbo].[GiangVien_KhoaHoc]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[GioHang]  WITH CHECK ADD FOREIGN KEY([MaNguoiDung])
REFERENCES [dbo].[NguoiDung] ([MaNguoiDung])
GO
ALTER TABLE [dbo].[HoaDon]  WITH CHECK ADD FOREIGN KEY([MaNguoiDung])
REFERENCES [dbo].[NguoiDung] ([MaNguoiDung])
GO
ALTER TABLE [dbo].[KhoaHoc]  WITH CHECK ADD FOREIGN KEY([MaKhuyenMai])
REFERENCES [dbo].[KhuyenMai] ([MaKhuyenMai])
GO
ALTER TABLE [dbo].[KhoaHoc]  WITH CHECK ADD FOREIGN KEY([MaTheLoai])
REFERENCES [dbo].[TheLoai] ([MaTheLoai])
GO
ALTER TABLE [dbo].[LuotThichKhoaHoc]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[LuotThichKhoaHoc]  WITH CHECK ADD FOREIGN KEY([MaNguoiDung])
REFERENCES [dbo].[NguoiDung] ([MaNguoiDung])
GO
ALTER TABLE [dbo].[TienDo]  WITH CHECK ADD FOREIGN KEY([MaKhoaHoc])
REFERENCES [dbo].[KhoaHoc] ([MaKhoaHoc])
GO
ALTER TABLE [dbo].[TienDo]  WITH CHECK ADD FOREIGN KEY([MaNguoiDung])
REFERENCES [dbo].[NguoiDung] ([MaNguoiDung])
GO
ALTER TABLE [dbo].[TienDoBaiHoc]  WITH CHECK ADD FOREIGN KEY([MaBaiHoc])
REFERENCES [dbo].[BaiHoc] ([MaBaiHoc])
GO
ALTER TABLE [dbo].[TienDoBaiHoc]  WITH CHECK ADD FOREIGN KEY([MaTienDo])
REFERENCES [dbo].[TienDo] ([MaTienDo])
GO
ALTER TABLE [dbo].[DanhGia]  WITH CHECK ADD CHECK  (([Rating]>=(0) AND [Rating]<=(5)))
GO
ALTER TABLE [dbo].[GiangVien_KhoaHoc]  WITH CHECK ADD CHECK  (([TyLeDoanhThu]>=(0) AND [TyLeDoanhThu]<=(100)))
GO
ALTER TABLE [dbo].[KhoaHoc]  WITH CHECK ADD CHECK  (([GiaGoc]>=(0)))
GO
ALTER TABLE [dbo].[KhoaHoc]  WITH CHECK ADD CHECK  (([TBDanhGia]>=(0) AND [TBDanhGia]<=(5)))
GO
ALTER TABLE [dbo].[NguoiDung]  WITH CHECK ADD CHECK  (([VaiTro]='Admin' OR [VaiTro]='GiaoVien' OR [VaiTro]='HocVien'))
GO
ALTER TABLE [dbo].[TienDo]  WITH CHECK ADD CHECK  (([PhanTramTienDo]>=(0) AND [PhanTramTienDo]<=(100)))
GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatTienDoBaiHoc]    Script Date: 27/3/2026 5:57:31 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Cập nhật tiến độ bài học & tiến độ khóa học tự động
CREATE PROCEDURE [dbo].[sp_CapNhatTienDoBaiHoc]
    @MaTienDo INT,
    @MaBaiHoc INT
AS
BEGIN
    -- 1. Đánh dấu hoàn thành bài học
    UPDATE TienDoBaiHoc SET DaHoanThanh = 1 WHERE MaTienDo = @MaTienDo AND MaBaiHoc = @MaBaiHoc;

    -- 2. Tính lại phần trăm khóa học
    DECLARE @MaKhoaHoc INT = (SELECT MaKhoaHoc FROM TienDo WHERE MaTienDo = @MaTienDo);
    DECLARE @TongBaiHoc INT = (SELECT COUNT(*) FROM BaiHoc b JOIN Chuong c ON b.MaChuong = c.MaChuong WHERE c.MaKhoaHoc = @MaKhoaHoc);
    DECLARE @BaiDaXong INT = (SELECT COUNT(*) FROM TienDoBaiHoc WHERE MaTienDo = @MaTienDo AND DaHoanThanh = 1);

    DECLARE @PhanTram FLOAT = CASE WHEN @TongBaiHoc = 0 THEN 0 ELSE (@BaiDaXong * 100.0 / @TongBaiHoc) END;

    -- 3. Cập nhật bảng TienDo
    UPDATE TienDo 
    SET PhanTramTienDo = @PhanTram,
        TinhTrang = CASE WHEN @PhanTram = 100 THEN N'Đã hoàn thành' ELSE N'Đang học' END
    WHERE MaTienDo = @MaTienDo;
END;
GO
USE [master]
GO
ALTER DATABASE [ELearning_DB] SET  READ_WRITE 
GO
