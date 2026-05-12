-- Tạo Database
CREATE DATABASE ELearning_DB;
GO
USE ELearning_DB;
GO

 --USE master;
 --GO

 --ALTER DATABASE ELearning_DB 
 --SET SINGLE_USER 
 --WITH ROLLBACK IMMEDIATE;

 --DROP DATABASE ELearning_DB;


-- ==========================================
-- 1. TẠO CÁC BẢNG ĐỘC LẬP (KHÔNG CÓ KHÓA NGOẠI)
-- ==========================================

-- Bảng Người dùng
CREATE TABLE NguoiDung (
    MaNguoiDung INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    MatKhau VARCHAR(255) NOT NULL,
    VaiTro NVARCHAR(20) CHECK (VaiTro IN ('HocVien','GiaoVien','Admin')),
    LinkAnhDaiDien VARCHAR(MAX),
    TieuSu NVARCHAR(MAX),
    TinhTrang NVARCHAR(50),
    NgayTao DATETIME DEFAULT GETDATE()
);

-- Bảng Khuyến mãi
CREATE TABLE KhuyenMai (
    MaKhuyenMai INT IDENTITY(1,1) PRIMARY KEY,
    TenChuongTrinh NVARCHAR(200),
    PhanTramGiam FLOAT,
    NgayBatDau DATETIME,
    NgayKetThuc DATETIME
);

-- Bảng Thể loại
CREATE TABLE TheLoai (
    MaTheLoai INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(MAX)
);

-- ==========================================
-- 2. TẠO CÁC BẢNG CÓ PHỤ THUỘC BẬC 1
-- ==========================================

-- Bảng Giỏ hàng
CREATE TABLE GioHang (
    MaGioHang INT IDENTITY(1,1) PRIMARY KEY,
    NgayTao DATETIME DEFAULT GETDATE(),
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung)
);

-- Bảng Hóa đơn
-- Bảng Hóa đơn
CREATE TABLE HoaDon (
    MaHoaDon INT IDENTITY(1,1) PRIMARY KEY,
    TongTien DECIMAL(18,2) NOT NULL,
    PhuongThucThanhToan NVARCHAR(100),
    TinhTrangThanhToan BIT DEFAULT 0, -- 0: Chờ thanh toán, 1: Đã thanh toán
    NgayTao DATETIME DEFAULT GETDATE(),
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung)
);


-- Bảng Khóa học (Trung tâm)
CREATE TABLE KhoaHoc (
    MaKhoaHoc INT IDENTITY(1,1) PRIMARY KEY,
    TieuDe NVARCHAR(255) NOT NULL,
    TieuDePhu NVARCHAR(255),
    MoTa NVARCHAR(MAX),
    GiaGoc DECIMAL(18,2) CHECK (GiaGoc >= 0),
    TinhTrang NVARCHAR(50),
    TBDanhGia FLOAT DEFAULT 0 CHECK (TBDanhGia >= 0 AND TBDanhGia <= 5),
    NgayTao DATETIME DEFAULT GETDATE(),
    NgayCapNhat DATETIME,
    MaTheLoai INT FOREIGN KEY REFERENCES TheLoai(MaTheLoai),
    KiNang NVARCHAR(MAX),
    AnhURL VARCHAR(MAX),
    MaKhuyenMai INT FOREIGN KEY REFERENCES KhuyenMai(MaKhuyenMai),
    ThoiGianHocDuKien INT,
    ThoiGianChoPhepTre INT
);

-- ==========================================
-- 3. TẠO CÁC BẢNG CÓ PHỤ THUỘC BẬC 2
-- ==========================================

CREATE TABLE GiangVien_KhoaHoc (
    MaKhoaHoc INT FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc),
    MaGiangVien INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung),
    LaGiangVienChinh BIT DEFAULT 0, 
    TyLeDoanhThu FLOAT DEFAULT 0 CHECK (TyLeDoanhThu >= 0 AND TyLeDoanhThu <= 100), 
    PRIMARY KEY (MaKhoaHoc, MaGiangVien) 
);

-- Bảng Chi tiết giỏ hàng (Items trong Giỏ hàng)
CREATE TABLE ChiTietGioHang (
    MaChiTietGioHang INT IDENTITY(1,1) PRIMARY KEY,
    Gia DECIMAL(18,2),
    MaKhoaHoc INT FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc),
    MaGioHang INT FOREIGN KEY REFERENCES GioHang(MaGioHang),
	CONSTRAINT UQ_GioHang_KhoaHoc UNIQUE(MaGioHang, MaKhoaHoc)
);

-- Bảng Chi tiết hóa đơn
CREATE TABLE ChiTietHoaDon (
    MaChiTietHoaDon INT IDENTITY(1,1) PRIMARY KEY,
    Gia DECIMAL(18,2),
    MaHoaDon INT FOREIGN KEY REFERENCES HoaDon(MaHoaDon),
    MaKhoaHoc INT FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc)
);

-- Bảng Đánh giá
CREATE TABLE DanhGia (
    MaDanhGia INT IDENTITY(1,1) PRIMARY KEY,
    Rating FLOAT CHECK (Rating >= 0 AND Rating <= 5),
    BinhLuan NVARCHAR(MAX),
    NgayDanhGia DATETIME DEFAULT GETDATE(),
    Thich INT DEFAULT 0,
    MaKhoaHoc INT FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc),
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung)
);

-- Bảng Chứng chỉ
CREATE TABLE ChungChi (
    MaChungChi INT IDENTITY(1,1) PRIMARY KEY,
    NgayPhat DATETIME DEFAULT GETDATE(),
    MaKhoaHoc INT FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc),
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung)
);


-- Bảng Tiến độ
CREATE TABLE TienDo (
    MaTienDo INT IDENTITY(1,1) PRIMARY KEY,
    NgayThamGia DATETIME DEFAULT GETDATE(),
    PhanTramTienDo FLOAT DEFAULT 0 CHECK (PhanTramTienDo >= 0 AND PhanTramTienDo <= 100),
    TinhTrang BIT DEFAULT 0, -- 0: Đang học (chưa hoàn thành), 1: Đã hoàn thành
    NgayKetThuc DATETIME,
    MaKhoaHoc INT FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc),
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) 
);

-- Bảng Chương
CREATE TABLE Chuong (
    MaChuong INT IDENTITY(1,1) PRIMARY KEY,
    TieuDe NVARCHAR(255) NOT NULL,
    MaKhoaHoc INT FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc)
);

-- ==========================================
-- 4. TẠO CÁC BẢNG CÓ PHỤ THUỘC BẬC 3 & 4
-- ==========================================

-- Bảng Bài học
CREATE TABLE BaiHoc (
    MaBaiHoc INT IDENTITY(1,1) PRIMARY KEY,
    LinkVideo VARCHAR(MAX),
    MaChuong INT FOREIGN KEY REFERENCES Chuong(MaChuong),
    BaiTap NVARCHAR(MAX),
    LyThuyet NVARCHAR(MAX)
);

-- Bảng Tiến độ bài học
CREATE TABLE TienDoBaiHoc (
    MaTienDoBaiHoc INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiHoc INT FOREIGN KEY REFERENCES BaiHoc(MaBaiHoc),
    DaHoanThanh BIT DEFAULT 0, -- Tương ứng với 0/1 trong hình
    LanCuoiXem DATETIME,
    ThoiGian INT, -- Lưu số phút hoặc số giây
	MaTienDo INT FOREIGN KEY REFERENCES TienDo(MaTienDo)
);
GO

-- 1. XÓA BẢNG THỪA (Recommendations)
IF OBJECT_ID('Recommendations', 'U') IS NOT NULL
BEGIN
    DROP TABLE Recommendations;
    PRINT N'Đã xóa bảng Recommendations thành công!';
END
GO

-- 1. Dọn dẹp bảng cũ (nếu có) để tránh lỗi khi người mới run code
IF OBJECT_ID('Course_Likes', 'U') IS NOT NULL
BEGIN
    DROP TABLE Course_Likes;
END;
GO

-- 2. Tạo bảng Lượt Thích Khóa Học thuần Việt
IF OBJECT_ID('LuotThichKhoaHoc', 'U') IS NULL
BEGIN
    CREATE TABLE LuotThichKhoaHoc (
        MaLuotThich INT IDENTITY(1,1) PRIMARY KEY,
        MaNguoiDung INT NOT NULL FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung),
        MaKhoaHoc INT NOT NULL FOREIGN KEY REFERENCES KhoaHoc(MaKhoaHoc),
        NgayTao DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_LuotThichKhoaHoc UNIQUE(MaNguoiDung, MaKhoaHoc)
    );
END;
GO

-- Bảng Thông báo
CREATE TABLE ThongBao (
    MaThongBao INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung),
    TieuDe NVARCHAR(255) NOT NULL,
    NoiDung NVARCHAR(MAX) NOT NULL,
    NgayTao DATETIME DEFAULT GETDATE() NOT NULL,
    DaDoc BIT DEFAULT 0 NOT NULL
);
GO

-- 3. Thêm dữ liệu mẫu
IF NOT EXISTS (
    SELECT 1 FROM LuotThichKhoaHoc lt
    JOIN NguoiDung nd ON lt.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON lt.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
)
INSERT INTO LuotThichKhoaHoc (MaNguoiDung, MaKhoaHoc, NgayTao)
SELECT nd.MaNguoiDung, kh.MaKhoaHoc, '2026-02-26'
FROM NguoiDung nd CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App';

IF NOT EXISTS (
    SELECT 1 FROM LuotThichKhoaHoc lt
    JOIN NguoiDung nd ON lt.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON lt.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO LuotThichKhoaHoc (MaNguoiDung, MaKhoaHoc, NgayTao)
SELECT nd.MaNguoiDung, kh.MaKhoaHoc, '2026-02-26'
FROM NguoiDung nd CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy';

IF NOT EXISTS (
    SELECT 1 FROM LuotThichKhoaHoc lt
    JOIN NguoiDung nd ON lt.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON lt.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'em.hoang@student.vn' AND kh.TieuDe = N'Machine Learning Cơ Bản'
)
INSERT INTO LuotThichKhoaHoc (MaNguoiDung, MaKhoaHoc, NgayTao)
SELECT nd.MaNguoiDung, kh.MaKhoaHoc, '2026-02-27'
FROM NguoiDung nd CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'em.hoang@student.vn' AND kh.TieuDe = N'Machine Learning Cơ Bản';
GO