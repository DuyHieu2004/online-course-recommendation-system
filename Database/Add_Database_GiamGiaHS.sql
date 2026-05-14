USE [ELearning_DB]
GO

-- =========================================================
-- 1. Bảng Hạng thành viên: Định nghĩa điều kiện phân hạng
-- =========================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[HangThanhVien]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[HangThanhVien] (
        [MaHang] INT IDENTITY(1,1) PRIMARY KEY,
        [TenHang] NVARCHAR(50) NOT NULL,
        [SoKhoaHocToiThieu] INT NOT NULL,
        [PhanTramUuDai] FLOAT NOT NULL
    );
    PRINT N'Đã tạo bảng HangThanhVien.';

    -- Thêm dữ liệu cấu hình mặc định (như bạn yêu cầu)
    INSERT INTO [dbo].[HangThanhVien] (TenHang, SoKhoaHocToiThieu, PhanTramUuDai)
    VALUES 
        (N'Thường', 0, 0),
        (N'Bạc', 3, 10),
        (N'Vàng', 7, 20),
        (N'Kim Cương', 15, 30);
END
GO

-- =========================================================
-- 2. Bảng Người dùng: Thêm cột HangThanhVien
-- =========================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND name = 'HangThanhVien')
BEGIN
    ALTER TABLE [dbo].[NguoiDung] ADD [HangThanhVien] NVARCHAR(50) DEFAULT N'Thường';
    PRINT N'Đã thêm cột HangThanhVien vào bảng NguoiDung.';
END
GO

-- =========================================================
-- 3. Bảng Voucher_Hạng: Lưu mã giảm giá riêng cho từng hạng
-- =========================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Voucher_Hang]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Voucher_Hang] (
        [MaVoucher] INT IDENTITY(1,1) PRIMARY KEY,
        [MaHang] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[HangThanhVien]([MaHang]),
        [MaCode] VARCHAR(50) NOT NULL,
        [TieuDe] NVARCHAR(255) NULL,
        [NgayTao] DATETIME DEFAULT GETDATE()
    );
    PRINT N'Đã tạo bảng Voucher_Hang.';
    
    -- Insert sẵn một số mã Voucher mẫu để Backend lấy ra dùng
    DECLARE @MaBac INT = (SELECT MaHang FROM HangThanhVien WHERE TenHang = N'Bạc');
    DECLARE @MaVang INT = (SELECT MaHang FROM HangThanhVien WHERE TenHang = N'Vàng');
    DECLARE @MaKimCuong INT = (SELECT MaHang FROM HangThanhVien WHERE TenHang = N'Kim Cương');
    
    IF @MaBac IS NOT NULL
        INSERT INTO [dbo].[Voucher_Hang] (MaHang, MaCode, TieuDe) VALUES (@MaBac, 'UP-BAC-10', N'Voucher giảm 10% dành cho hạng Bạc');
    IF @MaVang IS NOT NULL
        INSERT INTO [dbo].[Voucher_Hang] (MaHang, MaCode, TieuDe) VALUES (@MaVang, 'UP-VANG-20', N'Voucher giảm 20% dành cho hạng Vàng');
    IF @MaKimCuong IS NOT NULL
        INSERT INTO [dbo].[Voucher_Hang] (MaHang, MaCode, TieuDe) VALUES (@MaKimCuong, 'UP-KC-30', N'Voucher giảm 30% VIP Kim Cương');
END
GO

-- =========================================================
-- 4. Bảng Thông báo: Tận dụng và mở rộng ThongBaoKhoaHoc
-- =========================================================
-- 4.1. Cho phép MaKhoaHoc NULL (vì thông báo voucher thì không gắn với khóa học nào cả)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ThongBaoKhoaHoc]') AND name = 'MaKhoaHoc')
BEGIN
    ALTER TABLE [dbo].[ThongBaoKhoaHoc] ALTER COLUMN [MaKhoaHoc] INT NULL;
END
GO

-- 4.2. Thêm cột MaNguoiDung để gửi đích danh cho từng người và LoaiThongBao để phân biệt
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ThongBaoKhoaHoc]') AND name = 'MaNguoiDung')
BEGIN
    ALTER TABLE [dbo].[ThongBaoKhoaHoc] ADD [MaNguoiDung] INT NULL FOREIGN KEY REFERENCES [dbo].[NguoiDung]([MaNguoiDung]);
    ALTER TABLE [dbo].[ThongBaoKhoaHoc] ADD [LoaiThongBao] VARCHAR(50) DEFAULT 'Course'; -- Các loại: Course, Voucher, System
    ALTER TABLE [dbo].[ThongBaoKhoaHoc] ADD [DaDoc] BIT DEFAULT 0;
    PRINT N'Đã mở rộng bảng ThongBaoKhoaHoc để hỗ trợ thông báo cá nhân.';
END
GO

-- =========================================================
-- 5. Cập nhật Hạng cho người dùng cũ dựa trên số lượng khóa học (Chạy 1 lần)
-- =========================================================
WITH DemKhoaHoc AS (
    SELECT 
        MaNguoiDung, 
        COUNT(MaKhoaHoc) AS SoKhoaHocDaMua
    FROM [dbo].[TienDo]
    GROUP BY MaNguoiDung
)
UPDATE nd
SET nd.HangThanhVien = 
    CASE 
        WHEN ISNULL(d.SoKhoaHocDaMua, 0) >= 15 THEN N'Kim Cương'
        WHEN ISNULL(d.SoKhoaHocDaMua, 0) >= 7  THEN N'Vàng'
        WHEN ISNULL(d.SoKhoaHocDaMua, 0) >= 3  THEN N'Bạc'
        ELSE N'Thường'
    END
FROM [dbo].[NguoiDung] nd
LEFT JOIN DemKhoaHoc d ON nd.MaNguoiDung = d.MaNguoiDung
WHERE nd.VaiTro = 'HocVien';
PRINT N'Đã cập nhật hạng cho toàn bộ Học viên hiện tại.';
GO

ALTER TABLE KhoaHoc ADD ThoiGianHocDuKien INT NULL;
ALTER TABLE KhoaHoc ADD ThoiGianChoPhepTre INT NULL;
ALTER TABLE TienDo ADD NgayKetThuc DATETIME NULL;

CREATE TABLE ThongBao (
    MaThongBao INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    TieuDe NVARCHAR(255) NOT NULL,
    NoiDung NVARCHAR(MAX) NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    DaDoc BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_ThongBao_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE
);