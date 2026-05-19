ALTER TABLE [dbo].[DanhGia]
ADD [Emotion] NVARCHAR(50) NULL;

-- 1. Cập nhật thời gian mặc định cho khóa học (12 tháng dự kiến, 30 ngày trễ)
UPDATE KhoaHoc 
SET ThoiGianHocDuKien = 12, ThoiGianChoPhepTre = 30 
WHERE ThoiGianHocDuKien IS NULL;

-- 2. Cập nhật NgayKetThuc cho các tiến độ cũ chưa có (NgayThamGia + 12 tháng + 30 ngày)
UPDATE TienDo 
SET NgayKetThuc = DATEADD(day, 30, DATEADD(month, 12, NgayThamGia))
WHERE NgayKetThuc IS NULL AND NgayThamGia IS NOT NULL;
GO

-- 3. Sửa Trigger: CHỈ chặn thêm vào giỏ hàng nếu khóa học ĐANG CÒN HẠN
ALTER TRIGGER [dbo].[trg_ChanMuaLaiKhoaHoc]
ON [dbo].[ChiTietGioHang]
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN GioHang gh ON i.MaGioHang = gh.MaGioHang
        JOIN TienDo td ON gh.MaNguoiDung = td.MaNguoiDung AND i.MaKhoaHoc = td.MaKhoaHoc
        WHERE td.NgayKetThuc IS NULL OR td.NgayKetThuc >= GETDATE() -- Thêm điều kiện này
    )
    BEGIN
        RAISERROR (N'Lỗi: Bạn đã sở hữu khóa học này và vẫn đang còn hạn, không thể thêm vào giỏ hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

SELECT 
    nd.MaNguoiDung,
    nd.Ten AS TenHocVien,
    nd.Email,
    kh.MaKhoaHoc,
    kh.TieuDe AS TenKhoaHoc,
    td.PhanTramTienDo,
    td.NgayThamGia,
    td.NgayKetThuc
FROM 
    TienDo td
JOIN 
    NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
JOIN 
    KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
WHERE 
    --td.NgayKetThuc < GETDATE() -- Điều kiện 1: Đã hết hạn (Ngày kết thúc nhỏ hơn ngày giờ hiện tại)
    ISNULL(td.PhanTramTienDo, 0) < 100 -- Điều kiện 2: Đang học (Tiến độ chưa đạt 100%)
ORDER BY 
    td.NgayKetThuc DESC; -- Sắp xếp những người mới hết hạn lên trên cùng




-- Ép các khóa học đang học dở của user 6651 có hạn chót là 15 ngày nữa (rơi vào vùng cảnh báo <= 1 tháng)
UPDATE TienDo
SET NgayKetThuc = DATEADD(day, 15, GETDATE())
WHERE MaNguoiDung = 10502 
  AND ISNULL(PhanTramTienDo, 0) < 100;

-- Thêm cột lưu Mã Voucher và Số Tiền Giảm vào bảng Hóa Đơn
ALTER TABLE [dbo].[HoaDon] ADD [MaVoucher] VARCHAR(50) NULL;
ALTER TABLE [dbo].[HoaDon] ADD [SoTienGiam] DECIMAL(18,2) DEFAULT 0;
GO

SELECT hd.*, cthd.*
FROM HoaDon hd
JOIN ChiTietHoaDon cthd
    ON hd.MaHoaDon = cthd.MaHoaDon
WHERE hd.MaHoaDon = (
    SELECT TOP 1 MaHoaDon
    FROM HoaDon
    ORDER BY NgayTao DESC
);