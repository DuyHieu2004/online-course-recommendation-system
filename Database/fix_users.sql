USE ELearning_DB;
GO
-- Xóa nếu tồn tại để test sạch
DELETE FROM NguoiDung WHERE Email = 'ht0912@master.com';
GO
-- Chèn lại với hash chuẩn cho mật khẩu '12345678'
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, TinhTrang, NgayTao) 
VALUES (N'User HT', 'ht0912@master.com', '73l8gRjwLftklgfdXT+MdiMEjJwGPVMsyVxe16iYpk8=', 'HocVien', N'Hoạt động', GETDATE());
GO
-- Update Admin1 nếu cần
UPDATE NguoiDung SET MatKhau = '73l8gRjwLftklgfdXT+MdiMEjJwGPVMsyVxe16iYpk8=' WHERE Email = 'admin1@elearning.vn';
GO
