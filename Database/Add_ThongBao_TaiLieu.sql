USE [ELearning_DB]
GO

-- 1. Thêm cột LinkTaiLieu vào bảng BaiHoc
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[BaiHoc]') 
    AND name = 'LinkTaiLieu'
)
BEGIN
    ALTER TABLE [dbo].[BaiHoc]
    ADD [LinkTaiLieu] VARCHAR(1000) NULL;
END
GO

-- 2. Tạo bảng ThongBaoKhoaHoc
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ThongBaoKhoaHoc]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ThongBaoKhoaHoc] (
        [MaThongBao] INT IDENTITY(1,1) PRIMARY KEY,
        [MaKhoaHoc] INT NOT NULL,
        [TieuDe] NVARCHAR(255) NOT NULL,
        [NoiDung] NVARCHAR(MAX) NOT NULL,
        [NgayTao] DATETIME DEFAULT GETDATE(),
        FOREIGN KEY ([MaKhoaHoc]) REFERENCES [dbo].[KhoaHoc]([MaKhoaHoc]) ON DELETE CASCADE
    );
END
GO
