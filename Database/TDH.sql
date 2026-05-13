-- Phải hoàn thành 100% khóa học mới được đánh giá và nhận chứng chỉ
create TRIGGER trg_KiemTraDieuKienDanhGia
ON DanhGia
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN TienDo t ON i.MaKhoaHoc = t.MaKhoaHoc AND i.MaNguoiDung = t.MaNguoiDung
        WHERE t.PhanTramTienDo < 100 OR t.PhanTramTienDo IS NULL
    )
    BEGIN
        -- Đã sửa thành %% để không lỗi format
        RAISERROR (N'Lỗi: Bạn phải hoàn thành 100%% khóa học mới được phép đánh giá!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Không được mua lại khóa học đã đăng ký
CREATE TRIGGER trg_ChanMuaLaiKhoaHoc
ON ChiTietGioHang
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN GioHang gh ON i.MaGioHang = gh.MaGioHang
        JOIN TienDo td ON gh.MaNguoiDung = td.MaNguoiDung AND i.MaKhoaHoc = td.MaKhoaHoc
    )
    BEGIN
        RAISERROR (N'Lỗi: Bạn đã sở hữu khóa học này, không thể thêm vào giỏ hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Cập nhật tiến độ bài học & tiến độ khóa học tự động
CREATE PROCEDURE sp_CapNhatTienDoBaiHoc
    @MaTienDo INT,
    @MaBaiHoc INT
AS
BEGIN
    -- 1. Đánh dấu hoàn thành bài học
    UPDATE TienDoBaiHoc SET DaHoanThanh = 1 WHERE MaTienDo = @MaTienDo AND MaBaiHoc = @MaBaiHoc;

    -- 2. Tính lại phần trăm khóa học
    DECLARE @MaKhoaHoc INT = (SELECT MaKhoaHoc FROM TienDo WHERE MaTienDo = @MaTienDo);
    DECLARE @TongBaiHoc INT = (SELECT COUNT(*) FROM BaiHoc b JOIN Chuong c ON b.MaChuong = c.MaChuong WHERE c.MaKhoaHoc = @MaKhoaHoc);
    DECLARE @BaiDaXong INT = (SELECT COUNT(*) FROM TienDoBaiHoc WHERE MaTienDo = @MaTienDo AND DaHoanThanh = 1);

    DECLARE @PhanTram FLOAT = CASE WHEN @TongBaiHoc = 0 THEN 0 ELSE (@BaiDaXong * 100.0 / @TongBaiHoc) END;

    -- 3. Cập nhật bảng TienDo
    UPDATE TienDo 
    SET PhanTramTienDo = @PhanTram,
        TinhTrang = CASE WHEN @PhanTram = 100 THEN N'Đã hoàn thành' ELSE N'Đang học' END
    WHERE MaTienDo = @MaTienDo;
END;
GO

-- Chỉ đánh giá tối đa 2 lần, Like tự do
CREATE TRIGGER trg_GioiHanDanhGia
ON DanhGia
FOR INSERT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*) FROM DanhGia d 
    JOIN inserted i ON d.MaNguoiDung = i.MaNguoiDung AND d.MaKhoaHoc = i.MaKhoaHoc;

    IF (@Count > 2) -- Bao gồm cả bản ghi đang insert
    BEGIN
        RAISERROR (N'Lỗi: Bạn chỉ được đánh giá tối đa 2 lần cho mỗi khóa học.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

--Tự động tính tổng tiền hóa đơn
CREATE TRIGGER trg_CapNhatTongTienHoaDon
ON ChiTietHoaDon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Lấy MaHoaDon bị ảnh hưởng
    DECLARE @MaHoaDon INT;
    SELECT TOP 1 @MaHoaDon = ISNULL(i.MaHoaDon, d.MaHoaDon) FROM inserted i FULL OUTER JOIN deleted d ON i.MaChiTietHoaDon = d.MaChiTietHoaDon;

    -- Update tổng tiền
    UPDATE HoaDon
    SET TongTien = ISNULL((SELECT SUM(Gia) FROM ChiTietHoaDon WHERE MaHoaDon = @MaHoaDon), 0)
    WHERE MaHoaDon = @MaHoaDon;
END;
GO

-- Logic Khuyến mãi (Hết date, Mapping, Tính giá sau giảm)
CREATE VIEW vw_KhoaHoc_GiaThucTe AS
SELECT 
    kh.MaKhoaHoc, kh.TieuDe, kh.GiaGoc,
    km.MaKhuyenMai, km.PhanTramGiam, km.NgayKetThuc,
    CASE 
        WHEN km.MaKhuyenMai IS NOT NULL AND km.NgayKetThuc >= GETDATE() THEN kh.GiaGoc * (1.0 - (km.PhanTramGiam / 100.0))
        ELSE kh.GiaGoc 
    END AS GiaSauGiam
FROM KhoaHoc kh
LEFT JOIN KhuyenMai km ON kh.MaKhuyenMai = km.MaKhuyenMai;
GO

-- Không cho Publish nếu chưa có Lession hoặc Giá = 0
CREATE TRIGGER trg_ChanPublishKhoaHoc
ON KhoaHoc
FOR UPDATE
AS
BEGIN
    IF UPDATE(TinhTrang)
    BEGIN
        IF EXISTS (
            SELECT 1 FROM inserted i
            WHERE i.TinhTrang = 'Published' 
            AND (
                i.GiaGoc IS NULL OR i.GiaGoc <= 0 
                OR NOT EXISTS (SELECT 1 FROM Chuong c JOIN BaiHoc b ON c.MaChuong = b.MaChuong WHERE c.MaKhoaHoc = i.MaKhoaHoc)
            )
        )
        BEGIN
            RAISERROR (N'Lỗi: Khóa học phải có giá > 0 và có ít nhất 1 bài học mới được Publish.', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END;
GO

-- Tự động tính thu nhập của giáo viên
IF OBJECT_ID('fn_TinhThuNhapGiaoVien', 'FN') IS NOT NULL
    DROP FUNCTION fn_TinhThuNhapGiaoVien;
GO

CREATE FUNCTION fn_TinhThuNhapGiaoVien (@MaGiaoVien INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongThuNhap DECIMAL(18,2);
    SELECT @TongThuNhap = SUM(ct.Gia * (gvk.TyLeDoanhThu / 100.0))
    FROM ChiTietHoaDon ct
    JOIN GiangVien_KhoaHoc gvk ON ct.MaKhoaHoc = gvk.MaKhoaHoc
    WHERE gvk.MaGiangVien = @MaGiaoVien;
    RETURN ISNULL(@TongThuNhap, 0);
END;
GO



