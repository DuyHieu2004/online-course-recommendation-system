-- Thêm cột TrinhDo vào bảng KhoaHoc
ALTER TABLE KhoaHoc ADD TrinhDo NVARCHAR(255);
GO

-- Cập nhật giá trị mặc định cho các khoá học hiện có
UPDATE KhoaHoc SET TrinhDo = N'Cơ bản' WHERE TrinhDo IS NULL;
GO
