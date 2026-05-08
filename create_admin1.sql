DECLARE @NewUserId INT;
DECLARE @NewHoaDonId INT;

-- 1. Insert User
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, TinhTrang, NgayTao)
VALUES ('Admin 1', 'admin1@elearning.vn', 'jZae727K08KaOmKSgOaGzww/XVqGr/PKEgIMkjrcbJI=', 'Admin', N'Hoạt động', GETDATE());

SET @NewUserId = SCOPE_IDENTITY();

-- 2. Insert HoaDon
INSERT INTO HoaDon (MaNguoiDung, NgayTao, TongTien, PhuongThucThanhToan, TinhTrangThanhToan)
VALUES (@NewUserId, GETDATE(), 1000000, 'CreditCard', 1);

SET @NewHoaDonId = SCOPE_IDENTITY();

-- 3. Insert ChiTietHoaDon
INSERT INTO ChiTietHoaDon (MaHoaDon, MaKhoaHoc, Gia)
VALUES (@NewHoaDonId, 1, 1000000);

-- 4. Insert TienDo (expired)
INSERT INTO TienDo (MaKhoaHoc, MaNguoiDung, NgayThamGia, PhanTramTienDo, TinhTrang, NgayKetThuc)
VALUES (1, @NewUserId, DATEADD(day, -30, GETDATE()), 45.5, 1, DATEADD(day, -5, GETDATE()));

SELECT @NewUserId AS NewUserId;
