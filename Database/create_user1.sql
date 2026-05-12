-- 1. Insert HoaDon for user 1
INSERT INTO HoaDon (MaNguoiDung, NgayTao, TongTien, PhuongThucThanhToan, TinhTrangThanhToan)
VALUES (1, GETDATE(), 1000000, 'CreditCard', 1);

DECLARE @NewHoaDonId INT = SCOPE_IDENTITY();

-- 2. Insert ChiTietHoaDon
INSERT INTO ChiTietHoaDon (MaHoaDon, MaKhoaHoc, Gia)
VALUES (@NewHoaDonId, 1, 1000000);

-- 3. Insert TienDo (expired)
INSERT INTO TienDo (MaKhoaHoc, MaNguoiDung, NgayThamGia, PhanTramTienDo, TinhTrang, NgayKetThuc)
VALUES (1, 1, DATEADD(day, -30, GETDATE()), 45.5, 1, DATEADD(day, -5, GETDATE()));
