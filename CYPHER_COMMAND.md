### 1. Create database with name is course

Map data from n file csv

### 2. Command of cypher to create ralationship, node,...

#### Tạo Constraint (Chạy 1 lần trước khi Import):
```cypher
	// Việc này sẽ khóa id (hoặc thuộc tính định danh) của các Node lại, đảm bảo Neo4j tuyệt đối 
	// không bao giờ tạo ra 2 node có cùng ID hoặc Tên, đồng thời tăng tốc độ import lên gấp nhiều lần.

	CREATE CONSTRAINT khoahoc_id IF NOT EXISTS FOR (kh:KhoaHoc) REQUIRE kh.id IS UNIQUE;
	CREATE CONSTRAINT nguoidung_id IF NOT EXISTS FOR (nd:NguoiDung) REQUIRE nd.id IS UNIQUE;
	CREATE CONSTRAINT theloai_id IF NOT EXISTS FOR (tl:TheLoai) REQUIRE tl.id IS UNIQUE;
	CREATE CONSTRAINT chude_ten IF NOT EXISTS FOR (cd:ChuDe) REQUIRE cd.ten IS UNIQUE;
	CREATE CONSTRAINT loaichuongtrinh_ten IF NOT EXISTS FOR (lct:LoaiChuongTrinh) REQUIRE lct.ten IS UNIQUE;				
```
#### Tạo nodes và relationships:
```cypher
	// ========================================================================
	// BƯỚC 1: IMPORT THỂ LOẠI (Từ file TheLoai.csv)
	// ========================================================================
	LOAD CSV WITH HEADERS FROM 'file:///TheLoai.csv' AS row
	WITH row WHERE row.MaTheLoai IS NOT NULL

	// Tạo nút Thể loại
	MERGE (tl:TheLoai {id: toInteger(row.MaTheLoai)})
	SET tl.ten = row.Ten,
		tl.moTa = row.MoTa;


	// ========================================================================
	// BƯỚC 2: IMPORT NGƯỜI DÙNG & GIẢNG VIÊN (Từ file NguoiDung.csv)
	// ========================================================================
	LOAD CSV WITH HEADERS FROM 'file:///NguoiDung.csv' AS row
	WITH row WHERE row.MaNguoiDung IS NOT NULL

	// Tạo nút Người Dùng gốc
	MERGE (nd:NguoiDung {id: toInteger(row.MaNguoiDung)})
	SET nd.ten = row.Ten, 
		nd.email = row.Email,
		nd.matKhau = row.MatKhau,
		nd.linkAnhDaiDien = row.LinkAnhDaiDien,
		nd.tieuSu = row.TieuSu,
		nd.tinhTrang = row.TinhTrang,
		nd.ngayTao = row.NgayTao,
		nd.vaiTro = row.VaiTro

	// Dùng FOREACH để gán thêm nhãn (Label) tùy thuộc vào Vai Trò của họ
	FOREACH (ignoreMe IN CASE WHEN row.VaiTro = 'GiaoVien' THEN [1] ELSE [] END | SET nd:GiangVien)
	FOREACH (ignoreMe IN CASE WHEN row.VaiTro = 'HocVien' THEN [1] ELSE [] END | SET nd:HocVien);


	// ========================================================================
	// BƯỚC 3: IMPORT KHÓA HỌC, CHỦ ĐỀ & LOẠI CHƯƠNG TRÌNH (Từ file KhoaHoc.csv)
	// ========================================================================
	LOAD CSV WITH HEADERS FROM 'file:///KhoaHoc.csv' AS row

	// Bộ lọc rỗng
	WITH row WHERE row.MaKhoaHoc IS NOT NULL AND row.MaTheLoai IS NOT NULL

	// --- BỘ LỌC LOẠI BỎ TRÙNG LẶP ---
	// Gom nhóm theo TieuDe, lấy cấu trúc dòng đầu tiên
	WITH row.TieuDe AS tieuDeKhoaHoc, collect(row)[0] AS row

	// 1. Tạo nút Khóa học (KhoaHoc)
	MERGE (kh:KhoaHoc {id: toInteger(row.MaKhoaHoc)})
	SET kh.tieuDe = tieuDeKhoaHoc, 
		kh.tieuDePhu = row.TieuDePhu,
		kh.moTa = row.MoTa,
		kh.giaGoc = toFloat(row.GiaGoc),
		kh.tinhTrang = row.TinhTrang,
		kh.urlAnh = row.AnhURL, 
		kh.danhGiaTrungBinh = toFloat(row.TBDanhGia),
		kh.ngayTao = row.NgayTao,
		kh.ngayCapNhat = row.NgayCapNhat,
		kh.maKhuyenMai = toFloat(row.MaKhuyenMai)

	// 2. Khớp với Thể loại (đã tạo ở bước 1) và tạo liên kết
	WITH kh, row
	MATCH (tl:TheLoai {id: toInteger(row.MaTheLoai)})
	MERGE (kh)-[:THUOC_VE]->(tl)

	// 3. Tạo nút Chủ đề (Từ cột KiNang)
	WITH kh, row
	WHERE row.KiNang IS NOT NULL
	UNWIND split(row.KiNang, ',') AS kiNang
	WITH kh, row, trim(kiNang) AS tenChuDe
	WHERE tenChuDe <> ''

	MERGE (cd:ChuDe {ten: tenChuDe})
	MERGE (kh)-[:CO_CHU_DE]->(cd)

	// 4. Tạo nút Loại chương trình (Từ cột Program Type)
	// Dùng WITH DISTINCT để gộp lại 1 dòng cho mỗi khóa học, tránh bị nhân bản số lượng do UNWIND ở trên
	WITH DISTINCT kh, row
	WHERE row.`Program Type` IS NOT NULL
	UNWIND split(row.`Program Type`, ',') AS loai
	WITH kh, trim(loai) AS tenLoai
	WHERE tenLoai <> ''

	MERGE (lct:LoaiChuongTrinh {ten: tenLoai})
	MERGE (kh)-[:THUOC_LOAI_CHUONG_TRINH]->(lct);


	// ========================================================================
	// BƯỚC 4: LIÊN KẾT GIẢNG VIÊN VÀ KHÓA HỌC (Từ file GiangVien_KhoaHoc.csv)
	// ========================================================================
	LOAD CSV WITH HEADERS FROM 'file:///GiangVien_KhoaHoc.csv' AS row
	WITH row WHERE row.MaKhoaHoc IS NOT NULL AND row.MaGiangVien IS NOT NULL

	// Khớp Khóa học và Giảng viên (Dùng nhãn GiangVien đã gán ở bước 2)
	MATCH (kh:KhoaHoc {id: toInteger(row.MaKhoaHoc)})
	MATCH (gv:GiangVien {id: toInteger(row.MaGiangVien)})

	// Tạo liên kết Giảng Dạy
	MERGE (gv)-[gd:GIANG_DAY]->(kh)
	SET gd.laGiangVienChinh = toInteger(row.LaGiangVienChinh),
		gd.tyLeDoanhThu = toFloat(row.TyLeDoanhThu);


	// ========================================================================
	// BƯỚC 5: IMPORT ĐÁNH GIÁ CỦA NGƯỜI DÙNG (Từ file DanhGia.csv)
	// ========================================================================
	LOAD CSV WITH HEADERS FROM 'file:///DanhGia.csv' AS row
	WITH row WHERE row.MaNguoiDung IS NOT NULL AND row.MaKhoaHoc IS NOT NULL AND row.Rating IS NOT NULL

	// --- LỌC TRÙNG LẶP ĐÁNH GIÁ ---
	// Đảm bảo 1 Người dùng và 1 Khóa học chỉ lấy 1 dòng dữ liệu đánh giá CUỐI CÙNG
	WITH row.MaNguoiDung AS maND, row.MaKhoaHoc AS maKH, collect(row)[-1] AS row

	// Khớp Người dùng và Khóa học
	MATCH (nd:NguoiDung {id: toInteger(maND)})
	MATCH (kh:KhoaHoc {id: toInteger(maKH)})

	// Tạo liên kết Đánh giá và lưu các thuộc tính liên quan
	MERGE (nd)-[dg:DANH_GIA]->(kh)
	SET dg.maDanhGia = toInteger(row.MaDanhGia),
		dg.diem = toFloat(row.Rating), 
		dg.binhLuan = row.BinhLuan,
		dg.ngayDanhGia = row.NgayDanhGia,
		dg.thich = toInteger(row.Thich);
```

		
### 3. Access in Controller/RecommendationController.cs, change password or set up password on your NeO4J.

### 4. Content-based
#### Bước 1: Xóa dữ liệu cũ (Cleanup)
```cypher
// 1. Tương ứng với hàm deleteContentSimilarRelationships
MATCH ()-[r:CONTENT_SIMILAR]-()
DELETE r;

// 2. Tương ứng với hàm deleteProjection
// Xóa projection có tên 'contentGraph' nếu nó đang tồn tại
CALL gds.graph.drop('contentGraph', false);
```
#### Bước 2: Tạo đồ thị ảo (Graph Projection)
```cypher
CALL gds.graph.project(
    'contentGraph',
    ['KhoaHoc', 'ChuDe', 'LoaiChuongTrinh'],
    ['CO_CHU_DE', 'THUOC_LOAI_CHUONG_TRINH']
);
```
#### Bước 3: Chạy thuật toán Node Similarity
```cypher
CALL gds.nodeSimilarity.write('contentGraph', {
	nodeLabels:['KhoaHoc', 'ChuDe'],
	writeRelationshipType: 'CONTENT_SIMILAR',
	writeProperty: 'score',
	similarityCutoff: 0.3
});
```
#### A. Tìm các Course tương tự một Course cụ thể (Tương ứng getSimilarItems)
```cypher
// BƯỚC 1: Tìm các khóa học có nội dung tương tự với khóa học đang xem
MATCH (khGoc:KhoaHoc {id: $courseId})-[rel:CONTENT_SIMILAR]-(q:KhoaHoc)

// BƯỚC 2: Tìm các người dùng đã đánh giá khóa học được gợi ý (để đo đám đông tham gia)
MATCH (nd:NguoiDung)-[dg_q:DANH_GIA]->(q)
WITH q, 
		rel.score AS contentScore, 
		count(dg_q) AS soLuongDanhGia, 
		q.danhGiaTrungBinh AS saoTrungBinh
WHERE soLuongDanhGia > 0

// BƯỚC 3: Tính điểm tổng hợp (Công thức Trọng số cho Khóa học cụ thể)
// Ở đây không có rating của user nên chia lại trọng số:
// - contentScore (50%): Mức độ giống nội dung chủ đề và chương trình
// - saoTrungBinh (25%): Chất lượng cao
// - log10(soLuongDanhGia) (25%): Độ phổ biến / Số người tham gia
WITH q, 
		soLuongDanhGia, 
		saoTrungBinh,
		(contentScore * 0.5) + ((saoTrungBinh / 5.0) * 0.25) + (log10(soLuongDanhGia + 1) * 0.25) AS simScore

ORDER BY simScore DESC
LIMIT 10

RETURN q.id AS CourseId, 
		q.tieuDe AS Title, 
		simScore AS Score, 
		soLuongDanhGia AS TotalReviews, 
		saoTrungBinh AS AverageRating";
```
#### B. Gợi ý theo hồ sơ User (Tương ứng getProfilePageItems)
```cypher
// BƯỚC 1: Lấy danh sách ID khóa học user đã học để loại trừ (không gợi ý lại)
MATCH (nd:NguoiDung {id: $userId})-[:DANH_GIA]->(khDaHoc:KhoaHoc)
WITH collect(khDaHoc.id) AS ratedCourseIds

// BƯỚC 2: Lấy 5 khóa học user thích nhất làm 'Hồ sơ sở thích'
MATCH (nd:NguoiDung {id: $userId})-[dg:DANH_GIA]->(kh:KhoaHoc)
WITH ratedCourseIds, kh, (dg.diem / 5.0) AS normalizedRating
ORDER BY normalizedRating DESC
LIMIT 5

// BƯỚC 3: Tìm các khóa học tương tự về Nội dung (Chủ đề & Program Type từ GDS)
MATCH (kh)-[rel:CONTENT_SIMILAR]-(q:KhoaHoc)
WHERE NOT q.id IN ratedCourseIds

// BƯỚC 4: Tính toán Độ phổ biến (Đám đông) và Chất lượng (Điểm cao)
MATCH (aiDo:NguoiDung)-[dg_q:DANH_GIA]->(q)
WITH q, 
		rel.score AS contentScore, 
		normalizedRating, 
		count(dg_q) AS soLuongDanhGia, 
		q.danhGiaTrungBinh AS saoTrungBinh
WHERE soLuongDanhGia > 0 // Đảm bảo khóa học có người học

// BƯỚC 5: Chấm điểm tổng hợp (Công thức Trọng số)
// - contentScore (40%): Mức độ giống nội dung
// - normalizedRating (20%): Mức độ user thích khóa học gốc
// - saoTrungBinh (20%): Điểm sao trung bình cao
// - log10(soLuongDanhGia) (20%): Thưởng điểm cho khóa học có đông học viên
WITH q, 
		soLuongDanhGia, 
		saoTrungBinh,
		(contentScore * 0.4) + (normalizedRating * 0.2) + ((saoTrungBinh / 5.0) * 0.2) + (log10(soLuongDanhGia + 1) * 0.2) AS simScore

// Nhóm lại để tránh trùng lặp nếu q được gợi ý từ nhiều khóa gốc khác nhau
WITH q.id AS CourseId, q.tieuDe AS Title, max(simScore) AS FinalScore, soLuongDanhGia, saoTrungBinh
ORDER BY FinalScore DESC
LIMIT 10

RETURN CourseId, Title, FinalScore AS Score, soLuongDanhGia AS TotalReviews, saoTrungBinh AS AverageRating";

```

		
