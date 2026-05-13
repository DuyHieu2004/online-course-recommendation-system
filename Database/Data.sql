USE ELearning_DB;
GO
SET NOCOUNT ON;
GO

/*
============================================================
SEED DATA TEST CHO ĐỀ TÀI:
XÂY DỰNG HỆ THỐNG PHÂN PHỐI VÀ GỢI Ý KHÓA HỌC TRỰC TUYẾN

- Script này được viết theo schema hiện có trong SQL.txt.
- Các trigger / procedure đang có trong TDH.txt đã được tính đến.
- Các comment [TAG] dùng để bạn biết block nào phục vụ chức năng nào.

TÀI LIỆU ĐỐI CHIẾU:
1) Đề cương: có nhóm chức năng người học / giáo viên / marketing / quản trị,
   cùng yêu cầu gợi ý khóa học, like khóa học, đánh giá, chứng chỉ, tiến độ...
2) SQL.txt: schema hiện tại gồm NguoiDung, KhoaHoc, GioHang, HoaDon, TienDo,
   DanhGia, ChungChi, Chuong, BaiHoc, TienDoBaiHoc...
3) TDH.txt: trigger chặn mua lại khóa học, chặn đánh giá khi chưa 100%,
   procedure cập nhật tiến độ bài học, view giá sau giảm, trigger chặn publish,
   function tính thu nhập giáo viên.
============================================================
*/

/*
============================================================
[0] DỌN DỮ LIỆU CŨ (TÙY CHỌN)
- Mặc định KHÔNG chạy.
- Nếu muốn reset dữ liệu test, bỏ comment block dưới.
============================================================
*/
/*
DELETE FROM TienDoBaiHoc;
DELETE FROM BaiHoc;
DELETE FROM Chuong;
DELETE FROM ChungChi;
DELETE FROM DanhGia;
DELETE FROM TienDo;
DELETE FROM ChiTietHoaDon;
DELETE FROM HoaDon;
DELETE FROM ChiTietGioHang;
DELETE FROM GioHang;
DELETE FROM GiangVien_KhoaHoc;
DELETE FROM KhoaHoc;
DELETE FROM TheLoai;
DELETE FROM KhuyenMai;
DELETE FROM NguoiDung;

DBCC CHECKIDENT ('TienDoBaiHoc', RESEED, 0);
DBCC CHECKIDENT ('BaiHoc', RESEED, 0);
DBCC CHECKIDENT ('Chuong', RESEED, 0);
DBCC CHECKIDENT ('ChungChi', RESEED, 0);
DBCC CHECKIDENT ('DanhGia', RESEED, 0);
DBCC CHECKIDENT ('TienDo', RESEED, 0);
DBCC CHECKIDENT ('ChiTietHoaDon', RESEED, 0);
DBCC CHECKIDENT ('HoaDon', RESEED, 0);
DBCC CHECKIDENT ('ChiTietGioHang', RESEED, 0);
DBCC CHECKIDENT ('GioHang', RESEED, 0);
DBCC CHECKIDENT ('KhoaHoc', RESEED, 0);
DBCC CHECKIDENT ('TheLoai', RESEED, 0);
DBCC CHECKIDENT ('KhuyenMai', RESEED, 0);
DBCC CHECKIDENT ('NguoiDung', RESEED, 0);
*/
GO

/*
============================================================
[WEB_AUTH_01] / [APP_AUTH_01] DỮ LIỆU CHO CHỨC NĂNG ĐĂNG KÝ - ĐĂNG NHẬP
- Dùng bảng NguoiDung.
- Có đủ 3 vai trò: HocVien, GiaoVien, Admin.
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'admin1@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Quản trị hệ thống', 'admin1@elearning.vn', 'Hash@Admin123', N'Admin', 'https://img.local/admin1.png', N'Tài khoản quản trị tổng hệ thống.', N'Hoạt động', '2026-01-26');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'marketing@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Bộ phận marketing', 'marketing@elearning.vn', 'Hash@Marketing123', N'Admin', 'https://img.local/marketing.png', N'Dùng để quản lý khuyến mãi, giỏ hàng, báo cáo bán hàng.', N'Hoạt động', '2026-01-26');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'yen.nguyen@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'ThS. Nguyễn Hải Yến', 'yen.nguyen@elearning.vn', 'Hash@GVYen123', N'GiaoVien', 'https://img.local/gv-yen.png', N'Giảng viên ASP.NET Core và kiến trúc hệ thống.', N'Hoạt động', '2026-01-27');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'khoa.tran@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Trần Minh Khoa', 'khoa.tran@elearning.vn', 'Hash@GVKhoa123', N'GiaoVien', 'https://img.local/gv-khoa.png', N'Giảng viên Data Science / Machine Learning.', N'Hoạt động', '2026-01-27');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'ha.le@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Lê Thu Hà', 'ha.le@elearning.vn', 'Hash@GVHa123', N'GiaoVien', 'https://img.local/gv-ha.png', N'Giảng viên UI/UX và DevOps căn bản.', N'Hoạt động', '2026-01-27');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'an.nguyen@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Nguyễn Văn An', 'an.nguyen@student.vn', 'Hash@HVAn123', N'HocVien', 'https://img.local/hv-an.png', N'Học viên thích web và backend.', N'Hoạt động', '2026-02-01');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'binh.tran@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Trần Gia Bình', 'binh.tran@student.vn', 'Hash@HVBinh123', N'HocVien', 'https://img.local/hv-binh.png', N'Học viên quan tâm React và Machine Learning.', N'Hoạt động', '2026-02-02');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'chi.le@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Lê Minh Chi', 'chi.le@student.vn', 'Hash@HVChi123', N'HocVien', 'https://img.local/hv-chi.png', N'Học viên đang hoàn thiện lộ trình fullstack.', N'Hoạt động', '2026-02-03');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'dung.pham@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Phạm Quốc Dũng', 'dung.pham@student.vn', 'Hash@HVDung123', N'HocVien', 'https://img.local/hv-dung.png', N'Học viên quan tâm data analysis.', N'Hoạt động', '2026-02-04');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'em.hoang@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Hoàng Gia Em', 'em.hoang@student.vn', 'Hash@HVEm123', N'HocVien', 'https://img.local/hv-em.png', N'Tài khoản mới để test giỏ hàng / mua khóa học lần đầu.', N'Hoạt động', '2026-02-05');
GO

/*
============================================================
[ADMIN_CAT_01] DỮ LIỆU CHO CHỨC NĂNG QUẢN LÝ DANH MỤC KHÓA HỌC
- Dùng bảng TheLoai.
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Lập trình Web')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Lập trình Web', N'Nhóm khóa học về ASP.NET Core, React, frontend/backend web.');

IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Data Science & AI')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Data Science & AI', N'Nhóm khóa học Python, phân tích dữ liệu, machine learning.');

IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Cloud & DevOps')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Cloud & DevOps', N'Nhóm khóa học Docker, CI/CD, triển khai hệ thống.');

IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Thiết kế UI/UX')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Thiết kế UI/UX', N'Nhóm khóa học Figma, thiết kế giao diện, trải nghiệm người dùng.');
GO

/*
============================================================
[MARKETING_PROMO_01] / [ADMIN_PROMO_01]
DỮ LIỆU CHO CHỨC NĂNG QUẢN LÝ KHUYẾN MÃI - GIẢM GIÁ
- Dùng bảng KhuyenMai.
- Có 1 khuyến mãi còn hạn và 1 khuyến mãi đã hết hạn để test view giá thực tế.
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE TenChuongTrinh = N'Back To School 20%')
INSERT INTO KhuyenMai (TenChuongTrinh, PhanTramGiam, NgayBatDau, NgayKetThuc)
VALUES (N'Back To School 20%', 20, '2026-02-01', '2026-12-31');

IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE TenChuongTrinh = N'AI Launch 15%')
INSERT INTO KhuyenMai (TenChuongTrinh, PhanTramGiam, NgayBatDau, NgayKetThuc)
VALUES (N'AI Launch 15%', 15, '2026-02-10', '2026-12-31');

IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE TenChuongTrinh = N'Tết 2026 - Hết hạn')
INSERT INTO KhuyenMai (TenChuongTrinh, PhanTramGiam, NgayBatDau, NgayKetThuc)
VALUES (N'Tết 2026 - Hết hạn', 30, '2026-01-01', '2026-01-31');
GO

/*
============================================================
[WEB_GV_01] TẠO / QUẢN LÝ KHÓA HỌC
[ADMIN_COURSE_01] DUYỆT NỘI DUNG KHÓA HỌC
- Dùng bảng KhoaHoc.
- Lưu ý: trigger trg_ChanPublishKhoaHoc trong TDH.txt kiểm tra đúng chuỗi 'Published'.
- Vì vậy script dùng các trạng thái: Published / Pending / Draft để khớp trigger hiện tại.
select * from KhoaHoc
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'ASP.NET Core từ Zero đến Deploy')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'ASP.NET Core từ Zero đến Deploy', N'Xây dựng web app và triển khai thực tế',
       N'Khóa học backend web với ASP.NET Core, EF Core, Identity, deploy IIS/Azure.',
       1499000, N'Published', 0, '2026-02-05', '2026-02-15',
       tl.MaTheLoai, N'ASP.NET Core, C#, EF Core, SQL Server, Identity, Deploy',
       'https://img.local/course-aspnet.png', km.MaKhuyenMai
FROM TheLoai tl CROSS JOIN KhuyenMai km
WHERE tl.Ten = N'Lập trình Web' AND km.TenChuongTrinh = N'Back To School 20%';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'ReactJS Thực Chiến cho Web App')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'ReactJS Thực Chiến cho Web App', N'Xây dựng SPA hiện đại',
       N'Khóa học ReactJS, routing, state management, gọi API và tổ chức component.',
       1299000, N'Published', 0, '2026-02-06', '2026-02-16',
       tl.MaTheLoai, N'ReactJS, JavaScript, Hooks, Router, API',
       'https://img.local/course-react.png', NULL
FROM TheLoai tl
WHERE tl.Ten = N'Lập trình Web';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Python cho Data Analysis')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Python cho Data Analysis', N'Phân tích dữ liệu với Pandas và Visualization',
       N'Học xử lý dữ liệu, trực quan hóa và thống kê cơ bản với Python.',
       999000, N'Published', 0, '2026-02-07', '2026-02-17',
       tl.MaTheLoai, N'Python, Pandas, NumPy, Matplotlib, Data Analysis',
       'https://img.local/course-python-data.png', km.MaKhuyenMai
FROM TheLoai tl CROSS JOIN KhuyenMai km
WHERE tl.Ten = N'Data Science & AI' AND km.TenChuongTrinh = N'Tết 2026 - Hết hạn';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Machine Learning Cơ Bản')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Machine Learning Cơ Bản', N'Các mô hình học máy cơ bản cho người mới',
       N'Học regression, classification, overfitting, pipeline và đánh giá mô hình.',
       1599000, N'Published', 0, '2026-02-08', '2026-02-18',
       tl.MaTheLoai, N'Machine Learning, Scikit-learn, Regression, Classification',
       'https://img.local/course-ml-basic.png', km.MaKhuyenMai
FROM TheLoai tl CROSS JOIN KhuyenMai km
WHERE tl.Ten = N'Data Science & AI' AND km.TenChuongTrinh = N'AI Launch 15%';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Docker & CI/CD cho người mới bắt đầu')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Docker & CI/CD cho người mới bắt đầu', N'Đóng gói ứng dụng và tự động triển khai',
       N'Khóa học Docker, container, docker compose và CI/CD pipeline cơ bản.',
       1199000, N'Pending', 0, '2026-02-09', '2026-02-19',
       tl.MaTheLoai, N'Docker, CI/CD, Container, Docker Compose',
       'https://img.local/course-docker-cicd.png', NULL
FROM TheLoai tl
WHERE tl.Ten = N'Cloud & DevOps';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Thiết kế UI/UX với Figma')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Thiết kế UI/UX với Figma', N'Khóa học nháp để test trigger publish',
       N'Khóa học đang ở trạng thái nháp, chưa có bài học, chưa sẵn sàng publish.',
       0, N'Draft', 0, '2026-02-10', '2026-02-20',
       tl.MaTheLoai, N'Figma, UI/UX, Wireframe, Prototype',
       'https://img.local/course-figma.png', NULL
FROM TheLoai tl
WHERE tl.Ten = N'Thiết kế UI/UX';
GO

/*
============================================================
[WEB_GV_02] PHÂN CÔNG GIẢNG VIÊN CHO KHÓA HỌC
[WEB_GV_05] TÍNH DOANH THU THEO TỈ LỆ / SỐ LƯỢNG HỌC VIÊN
- Dùng bảng GiangVien_KhoaHoc.
- Có 1 khóa học Machine Learning được chia doanh thu 70/30 để test báo cáo thu nhập.
select * from GiangVien_KhoaHoc
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'yen.nguyen@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'yen.nguyen@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND nd.Email = 'ha.le@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'khoa.tran@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'khoa.tran@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'khoa.tran@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 70
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'khoa.tran@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 0, 30
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'ha.le@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND nd.Email = 'ha.le@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Thiết kế UI/UX với Figma' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Thiết kế UI/UX với Figma' AND nd.Email = 'ha.le@elearning.vn';
GO

/*
============================================================
[WEB_GV_03] TẢI VIDEO / TÀI LIỆU / TẠO NỘI DUNG KHÓA HỌC
- Dùng bảng Chuong + BaiHoc.
- Các khóa Published có đầy đủ chương / bài học.
- Khóa Docker ở trạng thái Pending nhưng đã có bài học -> admin có thể duyệt publish thành công.
- Khóa Figma ở trạng thái Draft, giá = 0, chưa có bài học -> dùng để test trigger chặn publish.
============================================================
*/
-- ==================== KHÓA ASP.NET ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND c.TieuDe = N'Chương 1 - Tổng quan ASP.NET Core'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 1 - Tổng quan ASP.NET Core', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND c.TieuDe = N'Chương 2 - EF Core và Deploy'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 2 - EF Core và Deploy', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND bh.LyThuyet = N'Giới thiệu kiến trúc ASP.NET Core'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-01', c.MaChuong, N'Cài SDK .NET 8 và tạo project đầu tiên.', N'Giới thiệu kiến trúc ASP.NET Core'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND c.TieuDe = N'Chương 1 - Tổng quan ASP.NET Core';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND bh.LyThuyet = N'MVC, Controller, Routing'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-02', c.MaChuong, N'Tạo module quản lý khóa học.', N'MVC, Controller, Routing'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND c.TieuDe = N'Chương 1 - Tổng quan ASP.NET Core';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND bh.LyThuyet = N'Entity Framework Core và Migration'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-03', c.MaChuong, N'Tạo migration cho bảng khóa học.', N'Entity Framework Core và Migration'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND c.TieuDe = N'Chương 2 - EF Core và Deploy';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND bh.LyThuyet = N'Deploy IIS / Azure App Service'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-04', c.MaChuong, N'Deploy project demo lên IIS.', N'Deploy IIS / Azure App Service'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND c.TieuDe = N'Chương 2 - EF Core và Deploy';

-- ==================== KHÓA REACT ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND c.TieuDe = N'Chương 1 - Nền tảng ReactJS'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 1 - Nền tảng ReactJS', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND c.TieuDe = N'Chương 2 - Gọi API và Routing'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 2 - Gọi API và Routing', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND bh.LyThuyet = N'JSX, component, props, state'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-01', c.MaChuong, N'Tạo component card khóa học.', N'JSX, component, props, state'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND c.TieuDe = N'Chương 1 - Nền tảng ReactJS';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND bh.LyThuyet = N'Hooks: useState và useEffect'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-02', c.MaChuong, N'Tạo form login và quản lý state.', N'Hooks: useState và useEffect'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND c.TieuDe = N'Chương 1 - Nền tảng ReactJS';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND bh.LyThuyet = N'Gọi REST API bằng fetch / axios'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-03', c.MaChuong, N'Hiển thị danh sách khóa học từ API.', N'Gọi REST API bằng fetch / axios'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND c.TieuDe = N'Chương 2 - Gọi API và Routing';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND bh.LyThuyet = N'React Router và layout ứng dụng'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-04', c.MaChuong, N'Tạo route trang chi tiết khóa học.', N'React Router và layout ứng dụng'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND c.TieuDe = N'Chương 2 - Gọi API và Routing';

-- ==================== KHÓA PYTHON DATA ANALYSIS ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'Chương 1 - Làm quen dữ liệu'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 1 - Làm quen dữ liệu', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Python cho Data Analysis';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'Chương 2 - Trực quan hóa'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 2 - Trực quan hóa', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Python cho Data Analysis';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'NumPy và mảng dữ liệu'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-01', c.MaChuong, N'Thực hành tạo mảng và vector.', N'NumPy và mảng dữ liệu'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'Chương 1 - Làm quen dữ liệu';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'Pandas DataFrame và xử lý thiếu dữ liệu'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-02', c.MaChuong, N'Đọc CSV và xử lý missing values.', N'Pandas DataFrame và xử lý thiếu dữ liệu'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'Chương 1 - Làm quen dữ liệu';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'Matplotlib và biểu đồ cơ bản'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-03', c.MaChuong, N'Vẽ biểu đồ line và bar.', N'Matplotlib và biểu đồ cơ bản'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'Chương 2 - Trực quan hóa';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'Phân tích mô tả và insight dữ liệu'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-04', c.MaChuong, N'Viết báo cáo mô tả tập dữ liệu.', N'Phân tích mô tả và insight dữ liệu'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'Chương 2 - Trực quan hóa';

-- ==================== KHÓA MACHINE LEARNING ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND c.TieuDe = N'Chương 1 - Khái niệm nền tảng'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 1 - Khái niệm nền tảng', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Machine Learning Cơ Bản';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND c.TieuDe = N'Chương 2 - Huấn luyện và đánh giá'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 2 - Huấn luyện và đánh giá', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Machine Learning Cơ Bản';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND bh.LyThuyet = N'Regression và classification'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-01', c.MaChuong, N'Phân biệt supervised learning.', N'Regression và classification'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND c.TieuDe = N'Chương 1 - Khái niệm nền tảng';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND bh.LyThuyet = N'Overfitting, underfitting, bias-variance'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-02', c.MaChuong, N'Phân tích lỗi mô hình.', N'Overfitting, underfitting, bias-variance'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND c.TieuDe = N'Chương 1 - Khái niệm nền tảng';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND bh.LyThuyet = N'Pipeline, train/test split'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-03', c.MaChuong, N'Xây pipeline đơn giản bằng scikit-learn.', N'Pipeline, train/test split'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND c.TieuDe = N'Chương 2 - Huấn luyện và đánh giá';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND bh.LyThuyet = N'Accuracy, Precision, Recall, F1-score'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-04', c.MaChuong, N'Tính ma trận nhầm lẫn và F1-score.', N'Accuracy, Precision, Recall, F1-score'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND c.TieuDe = N'Chương 2 - Huấn luyện và đánh giá';

-- ==================== KHÓA DOCKER & CI/CD (PENDING nhưng đã có bài học) ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND c.TieuDe = N'Chương 1 - Docker Cơ Bản'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'Chương 1 - Docker Cơ Bản', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND bh.LyThuyet = N'Image, container, Dockerfile'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/docker-01', c.MaChuong, N'Viết Dockerfile cho web app.', N'Image, container, Dockerfile'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND c.TieuDe = N'Chương 1 - Docker Cơ Bản';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND bh.LyThuyet = N'Docker Compose và CI/CD pipeline'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/docker-02', c.MaChuong, N'Tạo docker-compose và pipeline cơ bản.', N'Docker Compose và CI/CD pipeline'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND c.TieuDe = N'Chương 1 - Docker Cơ Bản';
GO

/*
============================================================
[WEB_HV_02] / [APP_HV_02] TÌM MUA KHÓA HỌC - GIỎ HÀNG
[MARKETING_CART_01] QUẢN LÝ GIỎ HÀNG
- Dùng bảng GioHang + ChiTietGioHang.
- Mỗi học viên có 1 giỏ hàng.
- Lưu ý trigger trg_ChanMuaLaiKhoaHoc sẽ chặn thêm khóa học đã sở hữu (tức đã có TienDo).
- Vì vậy các cart item bên dưới chỉ là các khóa học học viên CHƯA sở hữu.
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'an.nguyen@student.vn'
)
INSERT INTO GioHang (NgayTao, MaNguoiDung)
SELECT '2026-02-20', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'binh.tran@student.vn'
)
INSERT INTO GioHang (NgayTao, MaNguoiDung)
SELECT '2026-02-20', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'chi.le@student.vn'
)
INSERT INTO GioHang (NgayTao, MaNguoiDung)
SELECT '2026-02-20', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'chi.le@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'dung.pham@student.vn'
)
INSERT INTO GioHang (NgayTao, MaNguoiDung)
SELECT '2026-02-20', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'dung.pham@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'em.hoang@student.vn'
)
INSERT INTO GioHang (NgayTao, MaNguoiDung)
SELECT '2026-02-20', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'em.hoang@student.vn';
GO

/*
[MARKETING_CART_02] ITEM TRONG GIỎ HÀNG
- Nguyễn Văn An: đang cân nhắc mua React + ML.
- Trần Gia Bình: đang cân nhắc mua Docker.
- Lê Minh Chi: đang cân nhắc mua Python.
- Phạm Quốc Dũng: đang cân nhắc mua ASP.NET.
- Hoàng Gia Em: tài khoản mới, giỏ hàng có React + Docker.
*/
IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1299000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'Machine Learning Cơ Bản'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1359150, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1199000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND kh.TieuDe = N'Python cho Data Analysis'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 999000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'chi.le@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'dung.pham@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1199200, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'dung.pham@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'em.hoang@student.vn' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1299000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND nd.Email = 'em.hoang@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'em.hoang@student.vn' AND kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1199000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'Docker & CI/CD cho người mới bắt đầu' AND nd.Email = 'em.hoang@student.vn';
GO

/*
============================================================
[MARKETING_ORDER_01] THANH TOÁN - HÓA ĐƠN - CHI TIẾT HÓA ĐƠN
- Dùng bảng HoaDon + ChiTietHoaDon.
- trigger trg_CapNhatTongTienHoaDon sẽ tự cộng tổng tiền sau khi insert item.
- Một số giá đã được nhập theo giá sau khuyến mãi để test nghiệp vụ thanh toán.
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'an.nguyen@student.vn' AND hd.NgayTao = '2026-02-11T09:00:00'
)
INSERT INTO HoaDon (TongTien, PhuongThucThanhToan, TinhTrangThanhToan, NgayTao, MaNguoiDung)
SELECT 0, N'VNPay', 1, '2026-02-11T09:00:00', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00'
)
INSERT INTO HoaDon (TongTien, PhuongThucThanhToan, TinhTrangThanhToan, NgayTao, MaNguoiDung)
SELECT 0, N'MoMo', 1, '2026-02-12T10:00:00', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'chi.le@student.vn' AND hd.NgayTao = '2026-02-13T11:00:00'
)
INSERT INTO HoaDon (TongTien, PhuongThucThanhToan, TinhTrangThanhToan, NgayTao, MaNguoiDung)
SELECT 0, N'Chuyển khoản', 1, '2026-02-13T11:00:00', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'chi.le@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'dung.pham@student.vn' AND hd.NgayTao = '2026-02-14T14:00:00'
)
INSERT INTO HoaDon (TongTien, PhuongThucThanhToan, TinhTrangThanhToan, NgayTao, MaNguoiDung)
SELECT 0, N'VNPay', 1, '2026-02-14T14:00:00', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'dung.pham@student.vn';

-- Hóa đơn pending để test trạng thái thanh toán
IF NOT EXISTS (
    SELECT 1 FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    WHERE nd.Email = 'em.hoang@student.vn' AND hd.NgayTao = '2026-02-15T15:00:00'
)
INSERT INTO HoaDon (TongTien, PhuongThucThanhToan, TinhTrangThanhToan, NgayTao, MaNguoiDung)
SELECT 0, N'VNPay', 0, '2026-02-15T15:00:00', nd.MaNguoiDung
FROM NguoiDung nd
WHERE nd.Email = 'em.hoang@student.vn';
GO

/*
[MARKETING_ORDER_02] CHI TIẾT HÓA ĐƠN
- Hóa đơn của An: ASP.NET (đã giảm 20%) + Python (khuyến mãi đã hết hạn => giữ nguyên giá).
- Hóa đơn của Bình: React + Machine Learning (đã giảm 15%).
- Hóa đơn của Chi: ASP.NET.
- Hóa đơn của Dũng: Python.
- Hóa đơn của Em: React nhưng chưa thanh toán hoàn tất.
*/
IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND hd.NgayTao = '2026-02-11T09:00:00' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1199200, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'an.nguyen@student.vn' AND hd.NgayTao = '2026-02-11T09:00:00' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND hd.NgayTao = '2026-02-11T09:00:00' AND kh.TieuDe = N'Python cho Data Analysis'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 999000, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'an.nguyen@student.vn' AND hd.NgayTao = '2026-02-11T09:00:00' AND kh.TieuDe = N'Python cho Data Analysis';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1299000, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'Machine Learning Cơ Bản'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1359150, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'Machine Learning Cơ Bản';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND hd.NgayTao = '2026-02-13T11:00:00' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1199200, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'chi.le@student.vn' AND hd.NgayTao = '2026-02-13T11:00:00' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'dung.pham@student.vn' AND hd.NgayTao = '2026-02-14T14:00:00' AND kh.TieuDe = N'Python cho Data Analysis'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 999000, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'dung.pham@student.vn' AND hd.NgayTao = '2026-02-14T14:00:00' AND kh.TieuDe = N'Python cho Data Analysis';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'em.hoang@student.vn' AND hd.NgayTao = '2026-02-15T15:00:00' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1299000, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'em.hoang@student.vn' AND hd.NgayTao = '2026-02-15T15:00:00' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App';
GO

/*
============================================================
[WEB_HV_03] / [APP_HV_03] THEO DÕI TIẾN ĐỘ HỌC
[WEB_HV_06] LỊCH SỬ KHÓA HỌC
[WEB_GV_04] QUẢN LÝ HỌC VIÊN CỦA KHÓA
- Dùng bảng TienDo.
- 4 trạng thái mẫu:
  + Đã hoàn thành 100%
  + Đang học 50%
  + Đang học 75%
  + Hóa đơn chờ thanh toán thì KHÔNG tạo tiến độ
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-11', 100, 1, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'Python cho Data Analysis'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-11', 50, 0, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-12', 75, 0, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Machine Learning Cơ Bản'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-12', 100, 1, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-13', 100, 1, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'chi.le@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'dung.pham@student.vn' AND kh.TieuDe = N'Python cho Data Analysis'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-14', 100, 1, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'dung.pham@student.vn';
GO

/*
============================================================
[WEB_HV_03B] / [APP_HV_03B] TIẾN ĐỘ TỪNG BÀI HỌC
- Dùng bảng TienDoBaiHoc.
- Dữ liệu được tạo theo bài học của từng khóa.
- Các tiến độ 100%: toàn bộ bài học đều hoàn thành.
- Nguyễn Văn An / Python: hoàn thành 2/4 bài -> 50%.
- Trần Gia Bình / React: hoàn thành 3/4 bài -> 75%.
============================================================
*/
-- 100% cho An - ASP.NET
INSERT INTO TienDoBaiHoc (MaBaiHoc, DaHoanThanh, LanCuoiXem, ThoiGian, MaTienDo)
SELECT bh.MaBaiHoc, 1, DATEADD(DAY, -3, GETDATE()), 1200, td.MaTienDo
FROM TienDo td
JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
WHERE nd.Email = 'an.nguyen@student.vn'
  AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
  AND NOT EXISTS (
      SELECT 1 FROM TienDoBaiHoc x
      WHERE x.MaTienDo = td.MaTienDo AND x.MaBaiHoc = bh.MaBaiHoc
  );

-- 50% cho An - Python (2/4 bài)
;WITH DS AS (
    SELECT td.MaTienDo, bh.MaBaiHoc,
           ROW_NUMBER() OVER (ORDER BY bh.MaBaiHoc) AS RN
    FROM TienDo td
    JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
    JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
    WHERE nd.Email = 'an.nguyen@student.vn'
      AND kh.TieuDe = N'Python cho Data Analysis'
)
INSERT INTO TienDoBaiHoc (MaBaiHoc, DaHoanThanh, LanCuoiXem, ThoiGian, MaTienDo)
SELECT DS.MaBaiHoc,
       CASE WHEN DS.RN <= 2 THEN 1 ELSE 0 END,
       CASE WHEN DS.RN <= 2 THEN DATEADD(DAY, -2, GETDATE()) ELSE NULL END,
       CASE WHEN DS.RN <= 2 THEN 900 ELSE 0 END,
       DS.MaTienDo
FROM DS
WHERE NOT EXISTS (
    SELECT 1 FROM TienDoBaiHoc x
    WHERE x.MaTienDo = DS.MaTienDo AND x.MaBaiHoc = DS.MaBaiHoc
);

-- 75% cho Bình - React (3/4 bài)
;WITH DS AS (
    SELECT td.MaTienDo, bh.MaBaiHoc,
           ROW_NUMBER() OVER (ORDER BY bh.MaBaiHoc) AS RN
    FROM TienDo td
    JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
    JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
    WHERE nd.Email = 'binh.tran@student.vn'
      AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
)
INSERT INTO TienDoBaiHoc (MaBaiHoc, DaHoanThanh, LanCuoiXem, ThoiGian, MaTienDo)
SELECT DS.MaBaiHoc,
       CASE WHEN DS.RN <= 3 THEN 1 ELSE 0 END,
       CASE WHEN DS.RN <= 3 THEN DATEADD(DAY, -1, GETDATE()) ELSE NULL END,
       CASE WHEN DS.RN <= 3 THEN 1100 ELSE 0 END,
       DS.MaTienDo
FROM DS
WHERE NOT EXISTS (
    SELECT 1 FROM TienDoBaiHoc x
    WHERE x.MaTienDo = DS.MaTienDo AND x.MaBaiHoc = DS.MaBaiHoc
);

-- 100% cho Bình - Machine Learning
INSERT INTO TienDoBaiHoc (MaBaiHoc, DaHoanThanh, LanCuoiXem, ThoiGian, MaTienDo)
SELECT bh.MaBaiHoc, 1, DATEADD(DAY, -5, GETDATE()), 1000, td.MaTienDo
FROM TienDo td
JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
WHERE nd.Email = 'binh.tran@student.vn'
  AND kh.TieuDe = N'Machine Learning Cơ Bản'
  AND NOT EXISTS (
      SELECT 1 FROM TienDoBaiHoc x
      WHERE x.MaTienDo = td.MaTienDo AND x.MaBaiHoc = bh.MaBaiHoc
  );

-- 100% cho Chi - ASP.NET
INSERT INTO TienDoBaiHoc (MaBaiHoc, DaHoanThanh, LanCuoiXem, ThoiGian, MaTienDo)
SELECT bh.MaBaiHoc, 1, DATEADD(DAY, -4, GETDATE()), 1250, td.MaTienDo
FROM TienDo td
JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
WHERE nd.Email = 'chi.le@student.vn'
  AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
  AND NOT EXISTS (
      SELECT 1 FROM TienDoBaiHoc x
      WHERE x.MaTienDo = td.MaTienDo AND x.MaBaiHoc = bh.MaBaiHoc
  );

-- 100% cho Dũng - Python
INSERT INTO TienDoBaiHoc (MaBaiHoc, DaHoanThanh, LanCuoiXem, ThoiGian, MaTienDo)
SELECT bh.MaBaiHoc, 1, DATEADD(DAY, -2, GETDATE()), 950, td.MaTienDo
FROM TienDo td
JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
WHERE nd.Email = 'dung.pham@student.vn'
  AND kh.TieuDe = N'Python cho Data Analysis'
  AND NOT EXISTS (
      SELECT 1 FROM TienDoBaiHoc x
      WHERE x.MaTienDo = td.MaTienDo AND x.MaBaiHoc = bh.MaBaiHoc
  );
GO

/*
============================================================
[WEB_HV_04] / [APP_HV_04] NHẬN CHỨNG CHỈ KHI HOÀN THÀNH KHÓA HỌC
- Dùng bảng ChungChi.
- Chỉ tạo chứng chỉ cho các học viên đã 100%.
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM ChungChi cc
    JOIN NguoiDung nd ON cc.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cc.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO ChungChi (NgayPhat, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-20', kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChungChi cc
    JOIN NguoiDung nd ON cc.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cc.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Machine Learning Cơ Bản'
)
INSERT INTO ChungChi (NgayPhat, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-21', kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChungChi cc
    JOIN NguoiDung nd ON cc.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cc.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy'
)
INSERT INTO ChungChi (NgayPhat, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-21', kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'chi.le@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChungChi cc
    JOIN NguoiDung nd ON cc.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cc.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'dung.pham@student.vn' AND kh.TieuDe = N'Python cho Data Analysis'
)
INSERT INTO ChungChi (NgayPhat, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-22', kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'dung.pham@student.vn';
GO

/*
============================================================
[WEB_HV_05] / [APP_HV_05] ĐÁNH GIÁ KHÓA HỌC
- Dùng bảng DanhGia.
- Trigger trg_KiemTraDieuKienDanhGia yêu cầu phải có TienDo = 100% mới insert được.
- Trigger trg_GioiHanDanhGia cho phép tối đa 2 đánh giá / user / course.
- Dữ liệu bên dưới có 1 học viên đánh giá 2 lần cùng 1 khóa để test giới hạn này.
- Cột Thich trong DanhGia được dùng như lượt thích cho review (theo schema hiện tại).
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND dg.BinhLuan = N'Nội dung dễ hiểu, phần deploy rất thực tế.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 5, N'Nội dung dễ hiểu, phần deploy rất thực tế.', '2026-02-21', 12, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND dg.BinhLuan = N'Bản cập nhật sau rất tốt, mong có thêm phần Docker.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 4.5, N'Bản cập nhật sau rất tốt, mong có thêm phần Docker.', '2026-02-25', 5, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Machine Learning Cơ Bản' AND dg.BinhLuan = N'Khóa ML cơ bản nhưng giải thích metric rất ổn.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 4.5, N'Khóa ML cơ bản nhưng giải thích metric rất ổn.', '2026-02-22', 7, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning Cơ Bản' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND dg.BinhLuan = N'Phù hợp cho người mới, ví dụ dễ theo dõi.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 4, N'Phù hợp cho người mới, ví dụ dễ theo dõi.', '2026-02-23', 3, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'chi.le@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'dung.pham@student.vn' AND kh.TieuDe = N'Python cho Data Analysis' AND dg.BinhLuan = N'Phần pandas và trực quan hóa rất hữu ích cho người mới.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 5, N'Phần pandas và trực quan hóa rất hữu ích cho người mới.', '2026-02-24', 6, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'dung.pham@student.vn';
GO

/*
============================================================
[ADMIN_REPORT_01] / [WEB_GV_05] CẬP NHẬT ĐIỂM TRUNG BÌNH KHÓA HỌC
- Schema hiện tại không có trigger tự cập nhật TBDanhGia.
- Vì vậy cập nhật thủ công để hỗ trợ chức năng xem báo cáo / thống kê.
============================================================
*/
UPDATE kh
SET kh.TBDanhGia = ISNULL(dg.AvgRating, 0),
    kh.NgayCapNhat = GETDATE()
FROM KhoaHoc kh
OUTER APPLY (
    SELECT AVG(CAST(d.Rating AS FLOAT)) AS AvgRating
    FROM DanhGia d
    WHERE d.MaKhoaHoc = kh.MaKhoaHoc
) dg;
GO


/*
============================================================
[TEST_QUERY_02] NGƯỜI HỌC - LỊCH SỬ ĐÃ MUA / ĐANG HỌC
============================================================
*/
SELECT 
    nd.Ten,
    kh.TieuDe,
    td.PhanTramTienDo,
    td.TinhTrang,
    mua.NgayMua
FROM TienDo td
JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
OUTER APPLY (
    SELECT TOP 1 hd.NgayTao AS NgayMua
    FROM HoaDon hd
    JOIN ChiTietHoaDon cthd ON hd.MaHoaDon = cthd.MaHoaDon
    WHERE hd.MaNguoiDung = nd.MaNguoiDung
      AND cthd.MaKhoaHoc = kh.MaKhoaHoc
    ORDER BY hd.NgayTao DESC
) mua
ORDER BY nd.Ten, mua.NgayMua, kh.TieuDe;
GO

/*
============================================================
[TEST_QUERY_03] GIÁO VIÊN - DANH SÁCH HỌC VIÊN CỦA KHÓA
============================================================
*/
 SELECT kh.TieuDe, nd.Ten AS HocVien, td.PhanTramTienDo, td.TinhTrang
 FROM TienDo td
 JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
 JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
 WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy';
GO

/*
============================================================
[TEST_QUERY_04] GIÁO VIÊN - DOANH THU / THU NHẬP
============================================================
*/
 SELECT nd.Ten AS GiangVien, dbo.fn_TinhThuNhapGiaoVien(nd.MaNguoiDung) AS TongThuNhap
 FROM NguoiDung nd
 WHERE nd.VaiTro = N'GiaoVien';
GO

/*
============================================================
[TEST_QUERY_05] QUẢN TRỊ - KHÓA HỌC CHỜ DUYỆT / NHÁP
============================================================
*/
 SELECT kh.MaKhoaHoc, kh.TieuDe, kh.TinhTrang, kh.GiaGoc, tl.Ten AS TheLoai
 FROM KhoaHoc kh
 JOIN TheLoai tl ON kh.MaTheLoai = tl.MaTheLoai
 WHERE kh.TinhTrang IN (N'Pending', N'Draft');
GO

/*
============================================================
[TEST_CASE_01] TEST TRIGGER CHẶN PUBLISH KHI CHƯA ĐỦ ĐIỀU KIỆN
- Khóa Figma đang Draft, giá = 0, chưa có bài học.
- Câu lệnh dưới KỲ VỌNG BỊ LỖI theo trigger trg_ChanPublishKhoaHoc.
============================================================
*/
 UPDATE KhoaHoc
 SET TinhTrang = N'Published'
 WHERE TieuDe = N'Thiết kế UI/UX với Figma';
GO

/*
============================================================
[TEST_CASE_02] TEST ADMIN DUYỆT KHÓA HỌC THÀNH CÔNG
- Khóa Docker đang Pending nhưng đã có bài học và giá > 0.
- Câu lệnh dưới KỲ VỌNG THÀNH CÔNG.
============================================================
*/
 UPDATE KhoaHoc
 SET TinhTrang = N'Published'
 WHERE TieuDe = N'Docker & CI/CD cho người mới bắt đầu';
GO

/*
============================================================
[TEST_CASE_03] TEST TRIGGER CHẶN ĐÁNH GIÁ KHI CHƯA HỌC XONG 100%
- Nguyễn Văn An đang học Python mới 50%.
- Câu lệnh dưới KỲ VỌNG BỊ LỖI theo trigger trg_KiemTraDieuKienDanhGia.
============================================================
*/
 INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
 SELECT 4, N'Em chưa học xong nhưng muốn đánh giá thử', GETDATE(), 0, kh.MaKhoaHoc, nd.MaNguoiDung
 FROM KhoaHoc kh CROSS JOIN NguoiDung nd
 WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'an.nguyen@student.vn';
GO

/*
============================================================
[TEST_CASE_04] TEST TRIGGER GIỚI HẠN TỐI ĐA 2 ĐÁNH GIÁ / KHÓA HỌC
- An đã có sẵn 2 đánh giá cho khóa ASP.NET.
- Câu lệnh dưới KỲ VỌNG BỊ LỖI theo trigger trg_GioiHanDanhGia.
============================================================
*/
 INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
 SELECT 5, N'Đánh giá thứ 3 - phải bị chặn', GETDATE(), 0, kh.MaKhoaHoc, nd.MaNguoiDung
 FROM KhoaHoc kh CROSS JOIN NguoiDung nd
 WHERE kh.TieuDe = N'ASP.NET Core từ Zero đến Deploy' AND nd.Email = 'an.nguyen@student.vn';
GO

/*
============================================================
[TEST_CASE_05] TEST TRIGGER CHẶN MUA LẠI KHÓA HỌC ĐÃ SỞ HỮU
- Dũng đã sở hữu Python cho Data Analysis (đã có TienDo).
- Câu lệnh dưới KỲ VỌNG BỊ LỖI theo trigger trg_ChanMuaLaiKhoaHoc.
============================================================
*/
 INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
 SELECT 999000, kh.MaKhoaHoc, gh.MaGioHang
 FROM KhoaHoc kh
 CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
 WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'dung.pham@student.vn';
GO

/*
============================================================
[TEST_CASE_06] TEST PROCEDURE CẬP NHẬT TIẾN ĐỘ BÀI HỌC
- Bình đang học React 75% (3/4 bài).
- Sau khi hoàn thành bài còn lại, chạy proc để tăng lên 100%.
============================================================
*/
 DECLARE @MaTienDo_BinhReact INT, @MaBaiHocConLai INT;
 SELECT @MaTienDo_BinhReact = td.MaTienDo
 FROM TienDo td
 JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
 JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
 WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'ReactJS Thực Chiến cho Web App';

 ;WITH DS AS (
     SELECT bh.MaBaiHoc,
            ROW_NUMBER() OVER (ORDER BY bh.MaBaiHoc) AS RN
     FROM KhoaHoc kh
     JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
     JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
     WHERE kh.TieuDe = N'ReactJS Thực Chiến cho Web App'
 )
 SELECT @MaBaiHocConLai = MaBaiHoc FROM DS WHERE RN = 4;

 EXEC sp_CapNhatTienDoBaiHoc @MaTienDo = @MaTienDo_BinhReact, @MaBaiHoc = @MaBaiHocConLai;
GO

/*
============================================================
[TEST_QUERY_06] GỢI Ý KHÓA HỌC (CHỈ DÙNG NẾU BẠN CHẠY BLOCK OPTIONAL_RECO_01)
============================================================
*/
-- SELECT nd.Ten, kh.TieuDe, r.score, r.created_at
-- FROM Recommendations r
-- JOIN NguoiDung nd ON r.user_id = nd.MaNguoiDung
-- JOIN KhoaHoc kh ON r.course_id = kh.MaKhoaHoc
-- ORDER BY nd.Ten, r.score DESC;
GO

/*
============================================================
[TEST_QUERY_07] LIKE KHÓA HỌC (CHỈ DÙNG NẾU BẠN CHẠY BLOCK OPTIONAL_LIKE_01)
============================================================
*/
-- SELECT nd.Ten, kh.TieuDe, cl.created_at
-- FROM Course_Likes cl
-- JOIN NguoiDung nd ON cl.user_id = nd.MaNguoiDung
-- JOIN KhoaHoc kh ON cl.course_id = kh.MaKhoaHoc
-- ORDER BY cl.created_at DESC;
GO

PRINT N'Đã seed dữ liệu test cho ELearning_DB.';


USE ELearning_DB;
GO

-- 1. Xóa toàn bộ dữ liệu hiện có (Xóa từ bảng con ngược lên bảng cha)
DELETE FROM TienDoBaiHoc;
DELETE FROM BaiHoc;
DELETE FROM Chuong;
DELETE FROM ChungChi;
DELETE FROM DanhGia;
DELETE FROM TienDo;
DELETE FROM ChiTietHoaDon;
DELETE FROM ChiTietGioHang;
DELETE FROM HoaDon;
DELETE FROM GioHang;
DELETE FROM GiangVien_KhoaHoc;
IF OBJECT_ID('LuotThichKhoaHoc', 'U') IS NOT NULL DELETE FROM LuotThichKhoaHoc;
DELETE FROM KhoaHoc;
DELETE FROM TheLoai;
DELETE FROM KhuyenMai;
DELETE FROM NguoiDung;
GO

-- 2. Reset lại bộ đếm ID (Identity) về số 0 để khi insert nó đếm lại cho chuẩn
DBCC CHECKIDENT ('TienDoBaiHoc', RESEED, 0);
DBCC CHECKIDENT ('BaiHoc', RESEED, 0);
DBCC CHECKIDENT ('Chuong', RESEED, 0);
DBCC CHECKIDENT ('ChungChi', RESEED, 0);
DBCC CHECKIDENT ('DanhGia', RESEED, 0);
DBCC CHECKIDENT ('TienDo', RESEED, 0);
DBCC CHECKIDENT ('ChiTietHoaDon', RESEED, 0);
DBCC CHECKIDENT ('HoaDon', RESEED, 0);
DBCC CHECKIDENT ('ChiTietGioHang', RESEED, 0);
DBCC CHECKIDENT ('GioHang', RESEED, 0);
DBCC CHECKIDENT ('KhoaHoc', RESEED, 0);
DBCC CHECKIDENT ('TheLoai', RESEED, 0);
DBCC CHECKIDENT ('KhuyenMai', RESEED, 0);
DBCC CHECKIDENT ('NguoiDung', RESEED, 0);
GO

PRINT N'Đã dọn dẹp xong toàn bộ database, sẵn sàng đón dữ liệu mới!';
