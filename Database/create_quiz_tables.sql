-- 1. Tạo bảng BaiKiemTra
CREATE TABLE [dbo].[BaiKiemTra] (
    [MaBaiKiemTra] INT IDENTITY(1,1) NOT NULL,
    [TieuDe] NVARCHAR(255) NOT NULL,
    [MoTa] NVARCHAR(MAX) NULL,
    [ThoiGianLamBai] INT NULL, -- Thời gian làm bài tính bằng phút
    [MaChuong] INT NULL,
    CONSTRAINT [PK_BaiKiemTra] PRIMARY KEY CLUSTERED ([MaBaiKiemTra] ASC),
    CONSTRAINT [FK_BaiKiemTra_Chuong] FOREIGN KEY ([MaChuong]) REFERENCES [dbo].[Chuong] ([id]) ON DELETE CASCADE
);
GO

-- 2. Tạo bảng CauHoi
CREATE TABLE [dbo].[CauHoi] (
    [MaCauHoi] INT IDENTITY(1,1) NOT NULL,
    [NoiDung] NVARCHAR(MAX) NOT NULL,
    [Diem] FLOAT NOT NULL DEFAULT 1.0,
    [MaBaiKiemTra] INT NULL,
    CONSTRAINT [PK_CauHoi] PRIMARY KEY CLUSTERED ([MaCauHoi] ASC),
    CONSTRAINT [FK_CauHoi_BaiKiemTra] FOREIGN KEY ([MaBaiKiemTra]) REFERENCES [dbo].[BaiKiemTra] ([MaBaiKiemTra]) ON DELETE CASCADE
);
GO

-- 3. Tạo bảng LuaChon (Đáp án cho từng câu hỏi)
CREATE TABLE [dbo].[LuaChon] (
    [MaLuaChon] INT IDENTITY(1,1) NOT NULL,
    [NoiDung] NVARCHAR(MAX) NOT NULL,
    [LaDapAnDung] BIT NOT NULL DEFAULT 0,
    [MaCauHoi] INT NULL,
    CONSTRAINT [PK_LuaChon] PRIMARY KEY CLUSTERED ([MaLuaChon] ASC),
    CONSTRAINT [FK_LuaChon_CauHoi] FOREIGN KEY ([MaCauHoi]) REFERENCES [dbo].[CauHoi] ([MaCauHoi]) ON DELETE CASCADE
);
GO

-- 4. Tạo bảng KetQuaKiemTra (Lưu kết quả thi của học viên)
CREATE TABLE [dbo].[KetQuaKiemTra] (
    [MaKetQua] INT IDENTITY(1,1) NOT NULL,
    [MaNguoiDung] INT NULL,
    [MaBaiKiemTra] INT NULL,
    [DiemSo] FLOAT NOT NULL DEFAULT 0,
    [NgayNopBai] DATETIME NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_KetQuaKiemTra] PRIMARY KEY CLUSTERED ([MaKetQua] ASC),
    CONSTRAINT [FK_KetQuaKiemTra_NguoiDung] FOREIGN KEY ([MaNguoiDung]) REFERENCES [dbo].[NguoiDung] ([id]) ON DELETE CASCADE,
    CONSTRAINT [FK_KetQuaKiemTra_BaiKiemTra] FOREIGN KEY ([MaBaiKiemTra]) REFERENCES [dbo].[BaiKiemTra] ([MaBaiKiemTra]) ON DELETE NO ACTION
);
GO
