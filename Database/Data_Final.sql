USE ELearning_DB;
GO
SET NOCOUNT ON;
GO

/*
============================================================
SEED DATA TEST CHO Äá»€ TÃ€I:
XÃ‚Y Dá»°NG Há»† THá»NG PHÃ‚N PHá»I VÃ€ Gá»¢I Ã KHÃ“A Há»ŒC TRá»°C TUYáº¾N

- Script nÃ y Ä‘Æ°á»£c viáº¿t theo schema hiá»‡n cÃ³ trong SQL.txt.
- CÃ¡c trigger / procedure Ä‘ang cÃ³ trong TDH.txt Ä‘Ã£ Ä‘Æ°á»£c tÃ­nh Ä‘áº¿n.
- CÃ¡c comment [TAG] dÃ¹ng Ä‘á»ƒ báº¡n biáº¿t block nÃ o phá»¥c vá»¥ chá»©c nÄƒng nÃ o.

TÃ€I LIá»†U Äá»I CHIáº¾U:
1) Äá» cÆ°Æ¡ng: cÃ³ nhÃ³m chá»©c nÄƒng ngÆ°á»i há»c / giÃ¡o viÃªn / marketing / quáº£n trá»‹,
   cÃ¹ng yÃªu cáº§u gá»£i Ã½ khÃ³a há»c, like khÃ³a há»c, Ä‘Ã¡nh giÃ¡, chá»©ng chá»‰, tiáº¿n Ä‘á»™...
2) SQL.txt: schema hiá»‡n táº¡i gá»“m NguoiDung, KhoaHoc, GioHang, HoaDon, TienDo,
   DanhGia, ChungChi, Chuong, BaiHoc, TienDoBaiHoc...
3) TDH.txt: trigger cháº·n mua láº¡i khÃ³a há»c, cháº·n Ä‘Ã¡nh giÃ¡ khi chÆ°a 100%,
   procedure cáº­p nháº­t tiáº¿n Ä‘á»™ bÃ i há»c, view giÃ¡ sau giáº£m, trigger cháº·n publish,
   function tÃ­nh thu nháº­p giÃ¡o viÃªn.
============================================================
*/

/*
============================================================
[0] Dá»ŒN Dá»® LIá»†U CÅ¨ (TÃ™Y CHá»ŒN)
- Máº·c Ä‘á»‹nh KHÃ”NG cháº¡y.
- Náº¿u muá»‘n reset dá»¯ liá»‡u test, bá» comment block dÆ°á»›i.
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
[WEB_AUTH_01] / [APP_AUTH_01] Dá»® LIá»†U CHO CHá»¨C NÄ‚NG ÄÄ‚NG KÃ - ÄÄ‚NG NHáº¬P
- DÃ¹ng báº£ng NguoiDung.
- CÃ³ Ä‘á»§ 3 vai trÃ²: HocVien, GiaoVien, Admin.
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'admin1@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Quáº£n trá»‹ há»‡ thá»‘ng', 'admin1@elearning.vn', 'Hash@Admin123', N'Admin', 'https://img.local/admin1.png', N'TÃ i khoáº£n quáº£n trá»‹ tá»•ng há»‡ thá»‘ng.', N'Hoáº¡t Ä‘á»™ng', '2026-01-26');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'marketing@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Bá»™ pháº­n marketing', 'marketing@elearning.vn', 'Hash@Marketing123', N'Admin', 'https://img.local/marketing.png', N'DÃ¹ng Ä‘á»ƒ quáº£n lÃ½ khuyáº¿n mÃ£i, giá» hÃ ng, bÃ¡o cÃ¡o bÃ¡n hÃ ng.', N'Hoáº¡t Ä‘á»™ng', '2026-01-26');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'yen.nguyen@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'ThS. Nguyá»…n Háº£i Yáº¿n', 'yen.nguyen@elearning.vn', 'Hash@GVYen123', N'GiaoVien', 'https://img.local/gv-yen.png', N'Giáº£ng viÃªn ASP.NET Core vÃ  kiáº¿n trÃºc há»‡ thá»‘ng.', N'Hoáº¡t Ä‘á»™ng', '2026-01-27');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'khoa.tran@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Tráº§n Minh Khoa', 'khoa.tran@elearning.vn', 'Hash@GVKhoa123', N'GiaoVien', 'https://img.local/gv-khoa.png', N'Giáº£ng viÃªn Data Science / Machine Learning.', N'Hoáº¡t Ä‘á»™ng', '2026-01-27');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'ha.le@elearning.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'LÃª Thu HÃ ', 'ha.le@elearning.vn', 'Hash@GVHa123', N'GiaoVien', 'https://img.local/gv-ha.png', N'Giáº£ng viÃªn UI/UX vÃ  DevOps cÄƒn báº£n.', N'Hoáº¡t Ä‘á»™ng', '2026-01-27');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'an.nguyen@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Nguyá»…n VÄƒn An', 'an.nguyen@student.vn', 'Hash@HVAn123', N'HocVien', 'https://img.local/hv-an.png', N'Há»c viÃªn thÃ­ch web vÃ  backend.', N'Hoáº¡t Ä‘á»™ng', '2026-02-01');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'binh.tran@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Tráº§n Gia BÃ¬nh', 'binh.tran@student.vn', 'Hash@HVBinh123', N'HocVien', 'https://img.local/hv-binh.png', N'Há»c viÃªn quan tÃ¢m React vÃ  Machine Learning.', N'Hoáº¡t Ä‘á»™ng', '2026-02-02');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'chi.le@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'LÃª Minh Chi', 'chi.le@student.vn', 'Hash@HVChi123', N'HocVien', 'https://img.local/hv-chi.png', N'Há»c viÃªn Ä‘ang hoÃ n thiá»‡n lá»™ trÃ¬nh fullstack.', N'Hoáº¡t Ä‘á»™ng', '2026-02-03');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'dung.pham@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'Pháº¡m Quá»‘c DÅ©ng', 'dung.pham@student.vn', 'Hash@HVDung123', N'HocVien', 'https://img.local/hv-dung.png', N'Há»c viÃªn quan tÃ¢m data analysis.', N'Hoáº¡t Ä‘á»™ng', '2026-02-04');

IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE Email = 'em.hoang@student.vn')
INSERT INTO NguoiDung (Ten, Email, MatKhau, VaiTro, LinkAnhDaiDien, TieuSu, TinhTrang, NgayTao)
VALUES (N'HoÃ ng Gia Em', 'em.hoang@student.vn', 'Hash@HVEm123', N'HocVien', 'https://img.local/hv-em.png', N'TÃ i khoáº£n má»›i Ä‘á»ƒ test giá» hÃ ng / mua khÃ³a há»c láº§n Ä‘áº§u.', N'Hoáº¡t Ä‘á»™ng', '2026-02-05');
GO

/*
============================================================
[ADMIN_CAT_01] Dá»® LIá»†U CHO CHá»¨C NÄ‚NG QUáº¢N LÃ DANH Má»¤C KHÃ“A Há»ŒC
- DÃ¹ng báº£ng TheLoai.
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Láº­p trÃ¬nh Web')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Láº­p trÃ¬nh Web', N'NhÃ³m khÃ³a há»c vá» ASP.NET Core, React, frontend/backend web.');

IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Data Science & AI')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Data Science & AI', N'NhÃ³m khÃ³a há»c Python, phÃ¢n tÃ­ch dá»¯ liá»‡u, machine learning.');

IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Cloud & DevOps')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Cloud & DevOps', N'NhÃ³m khÃ³a há»c Docker, CI/CD, triá»ƒn khai há»‡ thá»‘ng.');

IF NOT EXISTS (SELECT 1 FROM TheLoai WHERE Ten = N'Thiáº¿t káº¿ UI/UX')
INSERT INTO TheLoai (Ten, MoTa) VALUES (N'Thiáº¿t káº¿ UI/UX', N'NhÃ³m khÃ³a há»c Figma, thiáº¿t káº¿ giao diá»‡n, tráº£i nghiá»‡m ngÆ°á»i dÃ¹ng.');
GO

/*
============================================================
[MARKETING_PROMO_01] / [ADMIN_PROMO_01]
Dá»® LIá»†U CHO CHá»¨C NÄ‚NG QUáº¢N LÃ KHUYáº¾N MÃƒI - GIáº¢M GIÃ
- DÃ¹ng báº£ng KhuyenMai.
- CÃ³ 1 khuyáº¿n mÃ£i cÃ²n háº¡n vÃ  1 khuyáº¿n mÃ£i Ä‘Ã£ háº¿t háº¡n Ä‘á»ƒ test view giÃ¡ thá»±c táº¿.
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE TenChuongTrinh = N'Back To School 20%')
INSERT INTO KhuyenMai (TenChuongTrinh, PhanTramGiam, NgayBatDau, NgayKetThuc)
VALUES (N'Back To School 20%', 20, '2026-02-01', '2026-12-31');

IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE TenChuongTrinh = N'AI Launch 15%')
INSERT INTO KhuyenMai (TenChuongTrinh, PhanTramGiam, NgayBatDau, NgayKetThuc)
VALUES (N'AI Launch 15%', 15, '2026-02-10', '2026-12-31');

IF NOT EXISTS (SELECT 1 FROM KhuyenMai WHERE TenChuongTrinh = N'Táº¿t 2026 - Háº¿t háº¡n')
INSERT INTO KhuyenMai (TenChuongTrinh, PhanTramGiam, NgayBatDau, NgayKetThuc)
VALUES (N'Táº¿t 2026 - Háº¿t háº¡n', 30, '2026-01-01', '2026-01-31');
GO

/*
============================================================
[WEB_GV_01] Táº O / QUáº¢N LÃ KHÃ“A Há»ŒC
[ADMIN_COURSE_01] DUYá»†T Ná»˜I DUNG KHÃ“A Há»ŒC
- DÃ¹ng báº£ng KhoaHoc.
- LÆ°u Ã½: trigger trg_ChanPublishKhoaHoc trong TDH.txt kiá»ƒm tra Ä‘Ãºng chuá»—i 'Published'.
- VÃ¬ váº­y script dÃ¹ng cÃ¡c tráº¡ng thÃ¡i: Published / Pending / Draft Ä‘á»ƒ khá»›p trigger hiá»‡n táº¡i.
select * from KhoaHoc
============================================================
*/
IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy', N'XÃ¢y dá»±ng web app vÃ  triá»ƒn khai thá»±c táº¿',
       N'KhÃ³a há»c backend web vá»›i ASP.NET Core, EF Core, Identity, deploy IIS/Azure.',
       1499000, N'Published', 0, '2026-02-05', '2026-02-15',
       tl.MaTheLoai, N'ASP.NET Core, C#, EF Core, SQL Server, Identity, Deploy',
       'https://img.local/course-aspnet.png', km.MaKhuyenMai
FROM TheLoai tl CROSS JOIN KhuyenMai km
WHERE tl.Ten = N'Láº­p trÃ¬nh Web' AND km.TenChuongTrinh = N'Back To School 20%';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'ReactJS Thá»±c Chiáº¿n cho Web App', N'XÃ¢y dá»±ng SPA hiá»‡n Ä‘áº¡i',
       N'KhÃ³a há»c ReactJS, routing, state management, gá»i API vÃ  tá»• chá»©c component.',
       1299000, N'Published', 0, '2026-02-06', '2026-02-16',
       tl.MaTheLoai, N'ReactJS, JavaScript, Hooks, Router, API',
       'https://img.local/course-react.png', NULL
FROM TheLoai tl
WHERE tl.Ten = N'Láº­p trÃ¬nh Web';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Python cho Data Analysis')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Python cho Data Analysis', N'PhÃ¢n tÃ­ch dá»¯ liá»‡u vá»›i Pandas vÃ  Visualization',
       N'Há»c xá»­ lÃ½ dá»¯ liá»‡u, trá»±c quan hÃ³a vÃ  thá»‘ng kÃª cÆ¡ báº£n vá»›i Python.',
       999000, N'Published', 0, '2026-02-07', '2026-02-17',
       tl.MaTheLoai, N'Python, Pandas, NumPy, Matplotlib, Data Analysis',
       'https://img.local/course-python-data.png', km.MaKhuyenMai
FROM TheLoai tl CROSS JOIN KhuyenMai km
WHERE tl.Ten = N'Data Science & AI' AND km.TenChuongTrinh = N'Táº¿t 2026 - Háº¿t háº¡n';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Machine Learning CÆ¡ Báº£n')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Machine Learning CÆ¡ Báº£n', N'CÃ¡c mÃ´ hÃ¬nh há»c mÃ¡y cÆ¡ báº£n cho ngÆ°á»i má»›i',
       N'Há»c regression, classification, overfitting, pipeline vÃ  Ä‘Ã¡nh giÃ¡ mÃ´ hÃ¬nh.',
       1599000, N'Published', 0, '2026-02-08', '2026-02-18',
       tl.MaTheLoai, N'Machine Learning, Scikit-learn, Regression, Classification',
       'https://img.local/course-ml-basic.png', km.MaKhuyenMai
FROM TheLoai tl CROSS JOIN KhuyenMai km
WHERE tl.Ten = N'Data Science & AI' AND km.TenChuongTrinh = N'AI Launch 15%';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u', N'ÄÃ³ng gÃ³i á»©ng dá»¥ng vÃ  tá»± Ä‘á»™ng triá»ƒn khai',
       N'KhÃ³a há»c Docker, container, docker compose vÃ  CI/CD pipeline cÆ¡ báº£n.',
       1199000, N'Pending', 0, '2026-02-09', '2026-02-19',
       tl.MaTheLoai, N'Docker, CI/CD, Container, Docker Compose',
       'https://img.local/course-docker-cicd.png', NULL
FROM TheLoai tl
WHERE tl.Ten = N'Cloud & DevOps';

IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE TieuDe = N'Thiáº¿t káº¿ UI/UX vá»›i Figma')
INSERT INTO KhoaHoc (TieuDe, TieuDePhu, MoTa, GiaGoc, TinhTrang, TBDanhGia, NgayTao, NgayCapNhat, MaTheLoai, KiNang, AnhURL, MaKhuyenMai)
SELECT N'Thiáº¿t káº¿ UI/UX vá»›i Figma', N'KhÃ³a há»c nhÃ¡p Ä‘á»ƒ test trigger publish',
       N'KhÃ³a há»c Ä‘ang á»Ÿ tráº¡ng thÃ¡i nhÃ¡p, chÆ°a cÃ³ bÃ i há»c, chÆ°a sáºµn sÃ ng publish.',
       0, N'Draft', 0, '2026-02-10', '2026-02-20',
       tl.MaTheLoai, N'Figma, UI/UX, Wireframe, Prototype',
       'https://img.local/course-figma.png', NULL
FROM TheLoai tl
WHERE tl.Ten = N'Thiáº¿t káº¿ UI/UX';
GO

/*
============================================================
[WEB_GV_02] PHÃ‚N CÃ”NG GIáº¢NG VIÃŠN CHO KHÃ“A Há»ŒC
[WEB_GV_05] TÃNH DOANH THU THEO Tá»ˆ Lá»† / Sá» LÆ¯á»¢NG Há»ŒC VIÃŠN
- DÃ¹ng báº£ng GiangVien_KhoaHoc.
- CÃ³ 1 khÃ³a há»c Machine Learning Ä‘Æ°á»£c chia doanh thu 70/30 Ä‘á»ƒ test bÃ¡o cÃ¡o thu nháº­p.
select * from GiangVien_KhoaHoc
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'yen.nguyen@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'yen.nguyen@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND nd.Email = 'ha.le@elearning.vn';

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
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'khoa.tran@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 70
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'khoa.tran@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 0, 30
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'ha.le@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND nd.Email = 'ha.le@elearning.vn';

IF NOT EXISTS (
    SELECT 1 FROM GiangVien_KhoaHoc gvk
    JOIN KhoaHoc kh ON gvk.MaKhoaHoc = kh.MaKhoaHoc
    JOIN NguoiDung nd ON gvk.MaGiangVien = nd.MaNguoiDung
    WHERE kh.TieuDe = N'Thiáº¿t káº¿ UI/UX vá»›i Figma' AND nd.Email = 'ha.le@elearning.vn'
)
INSERT INTO GiangVien_KhoaHoc (MaKhoaHoc, MaGiangVien, LaGiangVienChinh, TyLeDoanhThu)
SELECT kh.MaKhoaHoc, nd.MaNguoiDung, 1, 100
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Thiáº¿t káº¿ UI/UX vá»›i Figma' AND nd.Email = 'ha.le@elearning.vn';
GO

/*
============================================================
[WEB_GV_03] Táº¢I VIDEO / TÃ€I LIá»†U / Táº O Ná»˜I DUNG KHÃ“A Há»ŒC
- DÃ¹ng báº£ng Chuong + BaiHoc.
- CÃ¡c khÃ³a Published cÃ³ Ä‘áº§y Ä‘á»§ chÆ°Æ¡ng / bÃ i há»c.
- KhÃ³a Docker á»Ÿ tráº¡ng thÃ¡i Pending nhÆ°ng Ä‘Ã£ cÃ³ bÃ i há»c -> admin cÃ³ thá»ƒ duyá»‡t publish thÃ nh cÃ´ng.
- KhÃ³a Figma á»Ÿ tráº¡ng thÃ¡i Draft, giÃ¡ = 0, chÆ°a cÃ³ bÃ i há»c -> dÃ¹ng Ä‘á»ƒ test trigger cháº·n publish.
============================================================
*/
-- ==================== KHÃ“A ASP.NET ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Tá»•ng quan ASP.NET Core'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 1 - Tá»•ng quan ASP.NET Core', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - EF Core vÃ  Deploy'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 2 - EF Core vÃ  Deploy', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND bh.LyThuyet = N'Giá»›i thiá»‡u kiáº¿n trÃºc ASP.NET Core'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-01', c.MaChuong, N'CÃ i SDK .NET 8 vÃ  táº¡o project Ä‘áº§u tiÃªn.', N'Giá»›i thiá»‡u kiáº¿n trÃºc ASP.NET Core'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Tá»•ng quan ASP.NET Core';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND bh.LyThuyet = N'MVC, Controller, Routing'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-02', c.MaChuong, N'Táº¡o module quáº£n lÃ½ khÃ³a há»c.', N'MVC, Controller, Routing'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Tá»•ng quan ASP.NET Core';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND bh.LyThuyet = N'Entity Framework Core vÃ  Migration'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-03', c.MaChuong, N'Táº¡o migration cho báº£ng khÃ³a há»c.', N'Entity Framework Core vÃ  Migration'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - EF Core vÃ  Deploy';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND bh.LyThuyet = N'Deploy IIS / Azure App Service'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/aspnet-04', c.MaChuong, N'Deploy project demo lÃªn IIS.', N'Deploy IIS / Azure App Service'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - EF Core vÃ  Deploy';

-- ==================== KHÃ“A REACT ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Ná»n táº£ng ReactJS'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 1 - Ná»n táº£ng ReactJS', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Gá»i API vÃ  Routing'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 2 - Gá»i API vÃ  Routing', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND bh.LyThuyet = N'JSX, component, props, state'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-01', c.MaChuong, N'Táº¡o component card khÃ³a há»c.', N'JSX, component, props, state'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Ná»n táº£ng ReactJS';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND bh.LyThuyet = N'Hooks: useState vÃ  useEffect'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-02', c.MaChuong, N'Táº¡o form login vÃ  quáº£n lÃ½ state.', N'Hooks: useState vÃ  useEffect'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Ná»n táº£ng ReactJS';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND bh.LyThuyet = N'Gá»i REST API báº±ng fetch / axios'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-03', c.MaChuong, N'Hiá»ƒn thá»‹ danh sÃ¡ch khÃ³a há»c tá»« API.', N'Gá»i REST API báº±ng fetch / axios'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Gá»i API vÃ  Routing';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND bh.LyThuyet = N'React Router vÃ  layout á»©ng dá»¥ng'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/react-04', c.MaChuong, N'Táº¡o route trang chi tiáº¿t khÃ³a há»c.', N'React Router vÃ  layout á»©ng dá»¥ng'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Gá»i API vÃ  Routing';

-- ==================== KHÃ“A PYTHON DATA ANALYSIS ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - LÃ m quen dá»¯ liá»‡u'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 1 - LÃ m quen dá»¯ liá»‡u', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Python cho Data Analysis';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Trá»±c quan hÃ³a'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 2 - Trá»±c quan hÃ³a', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Python cho Data Analysis';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'NumPy vÃ  máº£ng dá»¯ liá»‡u'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-01', c.MaChuong, N'Thá»±c hÃ nh táº¡o máº£ng vÃ  vector.', N'NumPy vÃ  máº£ng dá»¯ liá»‡u'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - LÃ m quen dá»¯ liá»‡u';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'Pandas DataFrame vÃ  xá»­ lÃ½ thiáº¿u dá»¯ liá»‡u'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-02', c.MaChuong, N'Äá»c CSV vÃ  xá»­ lÃ½ missing values.', N'Pandas DataFrame vÃ  xá»­ lÃ½ thiáº¿u dá»¯ liá»‡u'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - LÃ m quen dá»¯ liá»‡u';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'Matplotlib vÃ  biá»ƒu Ä‘á»“ cÆ¡ báº£n'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-03', c.MaChuong, N'Váº½ biá»ƒu Ä‘á»“ line vÃ  bar.', N'Matplotlib vÃ  biá»ƒu Ä‘á»“ cÆ¡ báº£n'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Trá»±c quan hÃ³a';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Python cho Data Analysis' AND bh.LyThuyet = N'PhÃ¢n tÃ­ch mÃ´ táº£ vÃ  insight dá»¯ liá»‡u'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/python-da-04', c.MaChuong, N'Viáº¿t bÃ¡o cÃ¡o mÃ´ táº£ táº­p dá»¯ liá»‡u.', N'PhÃ¢n tÃ­ch mÃ´ táº£ vÃ  insight dá»¯ liá»‡u'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Python cho Data Analysis' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Trá»±c quan hÃ³a';

-- ==================== KHÃ“A MACHINE LEARNING ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - KhÃ¡i niá»‡m ná»n táº£ng'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 1 - KhÃ¡i niá»‡m ná»n táº£ng', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n';

IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Huáº¥n luyá»‡n vÃ  Ä‘Ã¡nh giÃ¡'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 2 - Huáº¥n luyá»‡n vÃ  Ä‘Ã¡nh giÃ¡', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND bh.LyThuyet = N'Regression vÃ  classification'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-01', c.MaChuong, N'PhÃ¢n biá»‡t supervised learning.', N'Regression vÃ  classification'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - KhÃ¡i niá»‡m ná»n táº£ng';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND bh.LyThuyet = N'Overfitting, underfitting, bias-variance'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-02', c.MaChuong, N'PhÃ¢n tÃ­ch lá»—i mÃ´ hÃ¬nh.', N'Overfitting, underfitting, bias-variance'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - KhÃ¡i niá»‡m ná»n táº£ng';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND bh.LyThuyet = N'Pipeline, train/test split'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-03', c.MaChuong, N'XÃ¢y pipeline Ä‘Æ¡n giáº£n báº±ng scikit-learn.', N'Pipeline, train/test split'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Huáº¥n luyá»‡n vÃ  Ä‘Ã¡nh giÃ¡';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND bh.LyThuyet = N'Accuracy, Precision, Recall, F1-score'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/ml-04', c.MaChuong, N'TÃ­nh ma tráº­n nháº§m láº«n vÃ  F1-score.', N'Accuracy, Precision, Recall, F1-score'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND c.TieuDe = N'ChÆ°Æ¡ng 2 - Huáº¥n luyá»‡n vÃ  Ä‘Ã¡nh giÃ¡';

-- ==================== KHÃ“A DOCKER & CI/CD (PENDING nhÆ°ng Ä‘Ã£ cÃ³ bÃ i há»c) ====================
IF NOT EXISTS (
    SELECT 1 FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Docker CÆ¡ Báº£n'
)
INSERT INTO Chuong (TieuDe, MaKhoaHoc)
SELECT N'ChÆ°Æ¡ng 1 - Docker CÆ¡ Báº£n', kh.MaKhoaHoc
FROM KhoaHoc kh
WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND bh.LyThuyet = N'Image, container, Dockerfile'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/docker-01', c.MaChuong, N'Viáº¿t Dockerfile cho web app.', N'Image, container, Dockerfile'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Docker CÆ¡ Báº£n';

IF NOT EXISTS (
    SELECT 1 FROM BaiHoc bh JOIN Chuong c ON bh.MaChuong = c.MaChuong
    JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
    WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND bh.LyThuyet = N'Docker Compose vÃ  CI/CD pipeline'
)
INSERT INTO BaiHoc (LinkVideo, MaChuong, BaiTap, LyThuyet)
SELECT 'https://video.local/docker-02', c.MaChuong, N'Táº¡o docker-compose vÃ  pipeline cÆ¡ báº£n.', N'Docker Compose vÃ  CI/CD pipeline'
FROM Chuong c JOIN KhoaHoc kh ON c.MaKhoaHoc = kh.MaKhoaHoc
WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND c.TieuDe = N'ChÆ°Æ¡ng 1 - Docker CÆ¡ Báº£n';
GO

/*
============================================================
[WEB_HV_02] / [APP_HV_02] TÃŒM MUA KHÃ“A Há»ŒC - GIá»Ž HÃ€NG
[MARKETING_CART_01] QUáº¢N LÃ GIá»Ž HÃ€NG
- DÃ¹ng báº£ng GioHang + ChiTietGioHang.
- Má»—i há»c viÃªn cÃ³ 1 giá» hÃ ng.
- LÆ°u Ã½ trigger trg_ChanMuaLaiKhoaHoc sáº½ cháº·n thÃªm khÃ³a há»c Ä‘Ã£ sá»Ÿ há»¯u (tá»©c Ä‘Ã£ cÃ³ TienDo).
- VÃ¬ váº­y cÃ¡c cart item bÃªn dÆ°á»›i chá»‰ lÃ  cÃ¡c khÃ³a há»c há»c viÃªn CHÆ¯A sá»Ÿ há»¯u.
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
[MARKETING_CART_02] ITEM TRONG GIá»Ž HÃ€NG
- Nguyá»…n VÄƒn An: Ä‘ang cÃ¢n nháº¯c mua React + ML.
- Tráº§n Gia BÃ¬nh: Ä‘ang cÃ¢n nháº¯c mua Docker.
- LÃª Minh Chi: Ä‘ang cÃ¢n nháº¯c mua Python.
- Pháº¡m Quá»‘c DÅ©ng: Ä‘ang cÃ¢n nháº¯c mua ASP.NET.
- HoÃ ng Gia Em: tÃ i khoáº£n má»›i, giá» hÃ ng cÃ³ React + Docker.
*/
IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1299000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'Machine Learning CÆ¡ Báº£n'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1359150, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1199000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND nd.Email = 'binh.tran@student.vn';

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
    WHERE nd.Email = 'dung.pham@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1199200, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'dung.pham@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'em.hoang@student.vn' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1299000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND nd.Email = 'em.hoang@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietGioHang ct
    JOIN GioHang gh ON ct.MaGioHang = gh.MaGioHang
    JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON ct.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'em.hoang@student.vn' AND kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u'
)
INSERT INTO ChiTietGioHang (Gia, MaKhoaHoc, MaGioHang)
SELECT 1199000, kh.MaKhoaHoc, gh.MaGioHang
FROM KhoaHoc kh CROSS JOIN GioHang gh JOIN NguoiDung nd ON gh.MaNguoiDung = nd.MaNguoiDung
WHERE kh.TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u' AND nd.Email = 'em.hoang@student.vn';
GO

/*
============================================================
[MARKETING_ORDER_01] THANH TOÃN - HÃ“A ÄÆ N - CHI TIáº¾T HÃ“A ÄÆ N
- DÃ¹ng báº£ng HoaDon + ChiTietHoaDon.
- trigger trg_CapNhatTongTienHoaDon sáº½ tá»± cá»™ng tá»•ng tiá»n sau khi insert item.
- Má»™t sá»‘ giÃ¡ Ä‘Ã£ Ä‘Æ°á»£c nháº­p theo giÃ¡ sau khuyáº¿n mÃ£i Ä‘á»ƒ test nghiá»‡p vá»¥ thanh toÃ¡n.
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
SELECT 0, N'Chuyá»ƒn khoáº£n', 1, '2026-02-13T11:00:00', nd.MaNguoiDung
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

-- HÃ³a Ä‘Æ¡n pending Ä‘á»ƒ test tráº¡ng thÃ¡i thanh toÃ¡n
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
[MARKETING_ORDER_02] CHI TIáº¾T HÃ“A ÄÆ N
- HÃ³a Ä‘Æ¡n cá»§a An: ASP.NET (Ä‘Ã£ giáº£m 20%) + Python (khuyáº¿n mÃ£i Ä‘Ã£ háº¿t háº¡n => giá»¯ nguyÃªn giÃ¡).
- HÃ³a Ä‘Æ¡n cá»§a BÃ¬nh: React + Machine Learning (Ä‘Ã£ giáº£m 15%).
- HÃ³a Ä‘Æ¡n cá»§a Chi: ASP.NET.
- HÃ³a Ä‘Æ¡n cá»§a DÅ©ng: Python.
- HÃ³a Ä‘Æ¡n cá»§a Em: React nhÆ°ng chÆ°a thanh toÃ¡n hoÃ n táº¥t.
*/
IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND hd.NgayTao = '2026-02-11T09:00:00' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1199200, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'an.nguyen@student.vn' AND hd.NgayTao = '2026-02-11T09:00:00' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy';

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
    WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1299000, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'Machine Learning CÆ¡ Báº£n'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1359150, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'binh.tran@student.vn' AND hd.NgayTao = '2026-02-12T10:00:00' AND kh.TieuDe = N'Machine Learning CÆ¡ Báº£n';

IF NOT EXISTS (
    SELECT 1 FROM ChiTietHoaDon cthd
    JOIN HoaDon hd ON cthd.MaHoaDon = hd.MaHoaDon
    JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cthd.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND hd.NgayTao = '2026-02-13T11:00:00' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1199200, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'chi.le@student.vn' AND hd.NgayTao = '2026-02-13T11:00:00' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy';

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
    WHERE nd.Email = 'em.hoang@student.vn' AND hd.NgayTao = '2026-02-15T15:00:00' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App'
)
INSERT INTO ChiTietHoaDon (Gia, MaHoaDon, MaKhoaHoc)
SELECT 1299000, hd.MaHoaDon, kh.MaKhoaHoc
FROM HoaDon hd JOIN NguoiDung nd ON hd.MaNguoiDung = nd.MaNguoiDung
CROSS JOIN KhoaHoc kh
WHERE nd.Email = 'em.hoang@student.vn' AND hd.NgayTao = '2026-02-15T15:00:00' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App';
GO

/*
============================================================
[WEB_HV_03] / [APP_HV_03] THEO DÃ•I TIáº¾N Äá»˜ Há»ŒC
[WEB_HV_06] Lá»ŠCH Sá»¬ KHÃ“A Há»ŒC
[WEB_GV_04] QUáº¢N LÃ Há»ŒC VIÃŠN Cá»¦A KHÃ“A
- DÃ¹ng báº£ng TienDo.
- 4 tráº¡ng thÃ¡i máº«u:
  + ÄÃ£ hoÃ n thÃ nh 100%
  + Äang há»c 50%
  + Äang há»c 75%
  + HÃ³a Ä‘Æ¡n chá» thanh toÃ¡n thÃ¬ KHÃ”NG táº¡o tiáº¿n Ä‘á»™
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-11', 100, 1, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'an.nguyen@student.vn';

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
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-12', 75, 0, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Machine Learning CÆ¡ Báº£n'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-12', 100, 1, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM TienDo td JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
)
INSERT INTO TienDo (NgayThamGia, PhanTramTienDo, TinhTrang, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-13', 100, 1, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'chi.le@student.vn';

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
[WEB_HV_03B] / [APP_HV_03B] TIáº¾N Äá»˜ Tá»ªNG BÃ€I Há»ŒC
- DÃ¹ng báº£ng TienDoBaiHoc.
- Dá»¯ liá»‡u Ä‘Æ°á»£c táº¡o theo bÃ i há»c cá»§a tá»«ng khÃ³a.
- CÃ¡c tiáº¿n Ä‘á»™ 100%: toÃ n bá»™ bÃ i há»c Ä‘á»u hoÃ n thÃ nh.
- Nguyá»…n VÄƒn An / Python: hoÃ n thÃ nh 2/4 bÃ i -> 50%.
- Tráº§n Gia BÃ¬nh / React: hoÃ n thÃ nh 3/4 bÃ i -> 75%.
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
  AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
  AND NOT EXISTS (
      SELECT 1 FROM TienDoBaiHoc x
      WHERE x.MaTienDo = td.MaTienDo AND x.MaBaiHoc = bh.MaBaiHoc
  );

-- 50% cho An - Python (2/4 bÃ i)
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

-- 75% cho BÃ¬nh - React (3/4 bÃ i)
;WITH DS AS (
    SELECT td.MaTienDo, bh.MaBaiHoc,
           ROW_NUMBER() OVER (ORDER BY bh.MaBaiHoc) AS RN
    FROM TienDo td
    JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
    JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
    JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
    WHERE nd.Email = 'binh.tran@student.vn'
      AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App'
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

-- 100% cho BÃ¬nh - Machine Learning
INSERT INTO TienDoBaiHoc (MaBaiHoc, DaHoanThanh, LanCuoiXem, ThoiGian, MaTienDo)
SELECT bh.MaBaiHoc, 1, DATEADD(DAY, -5, GETDATE()), 1000, td.MaTienDo
FROM TienDo td
JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
WHERE nd.Email = 'binh.tran@student.vn'
  AND kh.TieuDe = N'Machine Learning CÆ¡ Báº£n'
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
  AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
  AND NOT EXISTS (
      SELECT 1 FROM TienDoBaiHoc x
      WHERE x.MaTienDo = td.MaTienDo AND x.MaBaiHoc = bh.MaBaiHoc
  );

-- 100% cho DÅ©ng - Python
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
[WEB_HV_04] / [APP_HV_04] NHáº¬N CHá»¨NG CHá»ˆ KHI HOÃ€N THÃ€NH KHÃ“A Há»ŒC
- DÃ¹ng báº£ng ChungChi.
- Chá»‰ táº¡o chá»©ng chá»‰ cho cÃ¡c há»c viÃªn Ä‘Ã£ 100%.
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM ChungChi cc
    JOIN NguoiDung nd ON cc.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cc.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
)
INSERT INTO ChungChi (NgayPhat, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-20', kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChungChi cc
    JOIN NguoiDung nd ON cc.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cc.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Machine Learning CÆ¡ Báº£n'
)
INSERT INTO ChungChi (NgayPhat, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-21', kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM ChungChi cc
    JOIN NguoiDung nd ON cc.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON cc.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy'
)
INSERT INTO ChungChi (NgayPhat, MaKhoaHoc, MaNguoiDung)
SELECT '2026-02-21', kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'chi.le@student.vn';

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
[WEB_HV_05] / [APP_HV_05] ÄÃNH GIÃ KHÃ“A Há»ŒC
- DÃ¹ng báº£ng DanhGia.
- Trigger trg_KiemTraDieuKienDanhGia yÃªu cáº§u pháº£i cÃ³ TienDo = 100% má»›i insert Ä‘Æ°á»£c.
- Trigger trg_GioiHanDanhGia cho phÃ©p tá»‘i Ä‘a 2 Ä‘Ã¡nh giÃ¡ / user / course.
- Dá»¯ liá»‡u bÃªn dÆ°á»›i cÃ³ 1 há»c viÃªn Ä‘Ã¡nh giÃ¡ 2 láº§n cÃ¹ng 1 khÃ³a Ä‘á»ƒ test giá»›i háº¡n nÃ y.
- Cá»™t Thich trong DanhGia Ä‘Æ°á»£c dÃ¹ng nhÆ° lÆ°á»£t thÃ­ch cho review (theo schema hiá»‡n táº¡i).
============================================================
*/
IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND dg.BinhLuan = N'Ná»™i dung dá»… hiá»ƒu, pháº§n deploy ráº¥t thá»±c táº¿.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 5, N'Ná»™i dung dá»… hiá»ƒu, pháº§n deploy ráº¥t thá»±c táº¿.', '2026-02-21', 12, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'an.nguyen@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND dg.BinhLuan = N'Báº£n cáº­p nháº­t sau ráº¥t tá»‘t, mong cÃ³ thÃªm pháº§n Docker.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 4.5, N'Báº£n cáº­p nháº­t sau ráº¥t tá»‘t, mong cÃ³ thÃªm pháº§n Docker.', '2026-02-25', 5, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'an.nguyen@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND dg.BinhLuan = N'KhÃ³a ML cÆ¡ báº£n nhÆ°ng giáº£i thÃ­ch metric ráº¥t á»•n.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 4.5, N'KhÃ³a ML cÆ¡ báº£n nhÆ°ng giáº£i thÃ­ch metric ráº¥t á»•n.', '2026-02-22', 7, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Machine Learning CÆ¡ Báº£n' AND nd.Email = 'binh.tran@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'chi.le@student.vn' AND kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND dg.BinhLuan = N'PhÃ¹ há»£p cho ngÆ°á»i má»›i, vÃ­ dá»¥ dá»… theo dÃµi.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 4, N'PhÃ¹ há»£p cho ngÆ°á»i má»›i, vÃ­ dá»¥ dá»… theo dÃµi.', '2026-02-23', 3, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'chi.le@student.vn';

IF NOT EXISTS (
    SELECT 1 FROM DanhGia dg
    JOIN NguoiDung nd ON dg.MaNguoiDung = nd.MaNguoiDung
    JOIN KhoaHoc kh ON dg.MaKhoaHoc = kh.MaKhoaHoc
    WHERE nd.Email = 'dung.pham@student.vn' AND kh.TieuDe = N'Python cho Data Analysis' AND dg.BinhLuan = N'Pháº§n pandas vÃ  trá»±c quan hÃ³a ráº¥t há»¯u Ã­ch cho ngÆ°á»i má»›i.'
)
INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
SELECT 5, N'Pháº§n pandas vÃ  trá»±c quan hÃ³a ráº¥t há»¯u Ã­ch cho ngÆ°á»i má»›i.', '2026-02-24', 6, kh.MaKhoaHoc, nd.MaNguoiDung
FROM KhoaHoc kh CROSS JOIN NguoiDung nd
WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'dung.pham@student.vn';
GO

/*
============================================================
[ADMIN_REPORT_01] / [WEB_GV_05] Cáº¬P NHáº¬T ÄIá»‚M TRUNG BÃŒNH KHÃ“A Há»ŒC
- Schema hiá»‡n táº¡i khÃ´ng cÃ³ trigger tá»± cáº­p nháº­t TBDanhGia.
- VÃ¬ váº­y cáº­p nháº­t thá»§ cÃ´ng Ä‘á»ƒ há»— trá»£ chá»©c nÄƒng xem bÃ¡o cÃ¡o / thá»‘ng kÃª.
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
[TEST_QUERY_02] NGÆ¯á»œI Há»ŒC - Lá»ŠCH Sá»¬ ÄÃƒ MUA / ÄANG Há»ŒC
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
[TEST_QUERY_03] GIÃO VIÃŠN - DANH SÃCH Há»ŒC VIÃŠN Cá»¦A KHÃ“A
============================================================
*/
 SELECT kh.TieuDe, nd.Ten AS HocVien, td.PhanTramTienDo, td.TinhTrang
 FROM TienDo td
 JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
 JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
 WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy';
GO

/*
============================================================
[TEST_QUERY_04] GIÃO VIÃŠN - DOANH THU / THU NHáº¬P
============================================================
*/
 SELECT nd.Ten AS GiangVien, dbo.fn_TinhThuNhapGiaoVien(nd.MaNguoiDung) AS TongThuNhap
 FROM NguoiDung nd
 WHERE nd.VaiTro = N'GiaoVien';
GO

/*
============================================================
[TEST_QUERY_05] QUáº¢N TRá»Š - KHÃ“A Há»ŒC CHá»œ DUYá»†T / NHÃP
============================================================
*/
 SELECT kh.MaKhoaHoc, kh.TieuDe, kh.TinhTrang, kh.GiaGoc, tl.Ten AS TheLoai
 FROM KhoaHoc kh
 JOIN TheLoai tl ON kh.MaTheLoai = tl.MaTheLoai
 WHERE kh.TinhTrang IN (N'Pending', N'Draft');
GO

/*
============================================================
[TEST_CASE_01] TEST TRIGGER CHáº¶N PUBLISH KHI CHÆ¯A Äá»¦ ÄIá»€U KIá»†N
- KhÃ³a Figma Ä‘ang Draft, giÃ¡ = 0, chÆ°a cÃ³ bÃ i há»c.
- CÃ¢u lá»‡nh dÆ°á»›i Ká»² Vá»ŒNG Bá»Š Lá»–I theo trigger trg_ChanPublishKhoaHoc.
============================================================
*/
 UPDATE KhoaHoc
 SET TinhTrang = N'Published'
 WHERE TieuDe = N'Thiáº¿t káº¿ UI/UX vá»›i Figma';
GO

/*
============================================================
[TEST_CASE_02] TEST ADMIN DUYá»†T KHÃ“A Há»ŒC THÃ€NH CÃ”NG
- KhÃ³a Docker Ä‘ang Pending nhÆ°ng Ä‘Ã£ cÃ³ bÃ i há»c vÃ  giÃ¡ > 0.
- CÃ¢u lá»‡nh dÆ°á»›i Ká»² Vá»ŒNG THÃ€NH CÃ”NG.
============================================================
*/
 UPDATE KhoaHoc
 SET TinhTrang = N'Published'
 WHERE TieuDe = N'Docker & CI/CD cho ngÆ°á»i má»›i báº¯t Ä‘áº§u';
GO

/*
============================================================
[TEST_CASE_03] TEST TRIGGER CHáº¶N ÄÃNH GIÃ KHI CHÆ¯A Há»ŒC XONG 100%
- Nguyá»…n VÄƒn An Ä‘ang há»c Python má»›i 50%.
- CÃ¢u lá»‡nh dÆ°á»›i Ká»² Vá»ŒNG Bá»Š Lá»–I theo trigger trg_KiemTraDieuKienDanhGia.
============================================================
*/
 INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
 SELECT 4, N'Em chÆ°a há»c xong nhÆ°ng muá»‘n Ä‘Ã¡nh giÃ¡ thá»­', GETDATE(), 0, kh.MaKhoaHoc, nd.MaNguoiDung
 FROM KhoaHoc kh CROSS JOIN NguoiDung nd
 WHERE kh.TieuDe = N'Python cho Data Analysis' AND nd.Email = 'an.nguyen@student.vn';
GO

/*
============================================================
[TEST_CASE_04] TEST TRIGGER GIá»šI Háº N Tá»I ÄA 2 ÄÃNH GIÃ / KHÃ“A Há»ŒC
- An Ä‘Ã£ cÃ³ sáºµn 2 Ä‘Ã¡nh giÃ¡ cho khÃ³a ASP.NET.
- CÃ¢u lá»‡nh dÆ°á»›i Ká»² Vá»ŒNG Bá»Š Lá»–I theo trigger trg_GioiHanDanhGia.
============================================================
*/
 INSERT INTO DanhGia (Rating, BinhLuan, NgayDanhGia, Thich, MaKhoaHoc, MaNguoiDung)
 SELECT 5, N'ÄÃ¡nh giÃ¡ thá»© 3 - pháº£i bá»‹ cháº·n', GETDATE(), 0, kh.MaKhoaHoc, nd.MaNguoiDung
 FROM KhoaHoc kh CROSS JOIN NguoiDung nd
 WHERE kh.TieuDe = N'ASP.NET Core tá»« Zero Ä‘áº¿n Deploy' AND nd.Email = 'an.nguyen@student.vn';
GO

/*
============================================================
[TEST_CASE_05] TEST TRIGGER CHáº¶N MUA Láº I KHÃ“A Há»ŒC ÄÃƒ Sá»ž Há»®U
- DÅ©ng Ä‘Ã£ sá»Ÿ há»¯u Python cho Data Analysis (Ä‘Ã£ cÃ³ TienDo).
- CÃ¢u lá»‡nh dÆ°á»›i Ká»² Vá»ŒNG Bá»Š Lá»–I theo trigger trg_ChanMuaLaiKhoaHoc.
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
[TEST_CASE_06] TEST PROCEDURE Cáº¬P NHáº¬T TIáº¾N Äá»˜ BÃ€I Há»ŒC
- BÃ¬nh Ä‘ang há»c React 75% (3/4 bÃ i).
- Sau khi hoÃ n thÃ nh bÃ i cÃ²n láº¡i, cháº¡y proc Ä‘á»ƒ tÄƒng lÃªn 100%.
============================================================
*/
 DECLARE @MaTienDo_BinhReact INT, @MaBaiHocConLai INT;
 SELECT @MaTienDo_BinhReact = td.MaTienDo
 FROM TienDo td
 JOIN NguoiDung nd ON td.MaNguoiDung = nd.MaNguoiDung
 JOIN KhoaHoc kh ON td.MaKhoaHoc = kh.MaKhoaHoc
 WHERE nd.Email = 'binh.tran@student.vn' AND kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App';

 ;WITH DS AS (
     SELECT bh.MaBaiHoc,
            ROW_NUMBER() OVER (ORDER BY bh.MaBaiHoc) AS RN
     FROM KhoaHoc kh
     JOIN Chuong c ON kh.MaKhoaHoc = c.MaKhoaHoc
     JOIN BaiHoc bh ON c.MaChuong = bh.MaChuong
     WHERE kh.TieuDe = N'ReactJS Thá»±c Chiáº¿n cho Web App'
 )
 SELECT @MaBaiHocConLai = MaBaiHoc FROM DS WHERE RN = 4;

 EXEC sp_CapNhatTienDoBaiHoc @MaTienDo = @MaTienDo_BinhReact, @MaBaiHoc = @MaBaiHocConLai;
GO

/*
============================================================
[TEST_QUERY_06] Gá»¢I Ã KHÃ“A Há»ŒC (CHá»ˆ DÃ™NG Náº¾U Báº N CHáº Y BLOCK OPTIONAL_RECO_01)
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
[TEST_QUERY_07] LIKE KHÃ“A Há»ŒC (CHá»ˆ DÃ™NG Náº¾U Báº N CHáº Y BLOCK OPTIONAL_LIKE_01)
============================================================
*/
-- SELECT nd.Ten, kh.TieuDe, cl.created_at
-- FROM Course_Likes cl
-- JOIN NguoiDung nd ON cl.user_id = nd.MaNguoiDung
-- JOIN KhoaHoc kh ON cl.course_id = kh.MaKhoaHoc
-- ORDER BY cl.created_at DESC;
GO

PRINT N'ÄÃ£ seed dá»¯ liá»‡u test cho ELearning_DB.';


USE ELearning_DB;
GO

-- 1. XÃ³a toÃ n bá»™ dá»¯ liá»‡u hiá»‡n cÃ³ (XÃ³a tá»« báº£ng con ngÆ°á»£c lÃªn báº£ng cha)
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
