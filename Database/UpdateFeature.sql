USE ELearning_DB;
GO

-- Thêm cột IsDeleted
ALTER TABLE [ELearning_DB].[dbo].[KhoaHoc]
ADD IsDeleted BIT NOT NULL DEFAULT 0;
GO

-- (Tùy chọn) Cập nhật lại toàn bộ dữ liệu cũ thành chưa xóa để chắc chắn
UPDATE [ELearning_DB].[dbo].[KhoaHoc]
SET IsDeleted = 0;
GO

CREATE OR ALTER TRIGGER trg_KhoaHoc_SoftDelete
ON [ELearning_DB].[dbo].[KhoaHoc]
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem có thao tác xóa nào đang cố gắng xóa khóa học KHÔNG phải Draft không
    IF EXISTS (
        SELECT 1 
        FROM deleted d
        WHERE d.TinhTrang != 'Draft' -- Hoặc d.TinhTrang = 'Published' tùy vào logic của bạn
    )
    BEGIN
        -- Nếu có, ném ra lỗi và hủy transaction
        RAISERROR (N'Lỗi: Không thể xóa khóa học đã được Public/Published. Chỉ cho phép xóa khóa học ở trạng thái Draft.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Nếu hợp lệ (toàn bộ là Draft), thực hiện cập nhật cờ IsDeleted = 1 thay vì xóa thật
    UPDATE kh
    SET kh.IsDeleted = 1
    FROM [ELearning_DB].[dbo].[KhoaHoc] kh
    INNER JOIN deleted d ON kh.MaKhoaHoc = d.MaKhoaHoc;
    
    PRINT N'Đã chuyển trạng thái khóa học thành IsDeleted = 1 thành công.';
END;
GO




-- Set mật khẩu thành '12345678' cho tài khoản admin
UPDATE NguoiDung 
SET MatKhau = '73l8gRjwLftklgfdXT+MdiMEjJwGPVMsyVxe16iYpk8=' 
WHERE Email = 'admin@elearn.vn';
GO