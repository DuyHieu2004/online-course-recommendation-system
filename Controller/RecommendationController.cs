using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Neo4j.Driver;
using online_course_recommendation_system.Configurations;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendationController : ControllerBase
    {
        private readonly IDriver _driver;
        private readonly Neo4jSettings _neo4jSettings;
        private readonly Data.AppDbContext _context;
        
        public RecommendationController(
            IDriver driver,
            IOptions<Neo4jSettings> neo4jOptions,
            Data.AppDbContext context)
        {
            _driver = driver;
            _neo4jSettings = neo4jOptions.Value;
            _context = context;
        }

        // 1. GỢI Ý DỰA TRÊN NGƯỜI DÙNG TƯƠNG ĐỒNG (Collaborative Filtering)
        [HttpGet("user-based/{userId}")]
        public async Task<IActionResult> GetUserBasedRecommendations(int userId)
        {
            var recommendedCourses = new List<object>();

            try
            {
                await using var session = _driver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));

                var query = @"
                    MATCH (u1:NguoiDung {id: $userId})-[r1:DANH_GIA]->(khChung:KhoaHoc)<-[r2:DANH_GIA]-(u2:NguoiDung)
                    WHERE u1 <> u2 AND r1.diem >= 4.0 AND r2.diem >= 4.0
                    MATCH (u2)-[r3:DANH_GIA]->(q:KhoaHoc)
                    WHERE r3.diem >= 4.0 AND NOT (u1)-[:DANH_GIA]->(q)
                    
                    OPTIONAL MATCH (aiDo:NguoiDung)-[dg_q:DANH_GIA]->(q)
                    OPTIONAL MATCH (gv:GiangVien)-[:GIANG_DAY]->(q)
                    
                    WITH q, count(DISTINCT u2) AS userCount, avg(r3.diem) AS avgRating, 
                         count(dg_q) AS soLuongDanhGia,
                         collect(gv.ten)[0] AS instructorName
                    
                    ORDER BY userCount DESC, avgRating DESC
                    LIMIT 10
                    
                    RETURN q.id AS CourseId, 
                           q.tieuDe AS Title, 
                           (userCount * avgRating) AS Score,
                           soLuongDanhGia AS TotalReviews, 
                           q.danhGiaTrungBinh AS AverageRating,
                           q.giaGoc AS OriginalPrice, 
                           q.urlAnh AS Image, 
                           instructorName AS Instructor";

                var result = await session.RunAsync(query, new { userId });
                await result.ForEachAsync(record =>
                {
                    recommendedCourses.Add(new
                    {
                        CourseId = record["CourseId"].As<long>(),
                        Title = record["Title"]?.As<string>() ?? "Chưa có tiêu đề",
                        Score = record["Score"]?.As<double?>() ?? 0.0,
                        TotalReviews = record["TotalReviews"]?.As<long?>() ?? 0,
                        AverageRating = record["AverageRating"]?.As<double?>() ?? 0.0,
                        OriginalPrice = record["OriginalPrice"]?.As<double?>() ?? 0.0,
                        Image = record["Image"]?.As<string>() ?? "",
                        Instructor = record["Instructor"]?.As<string>() ?? "Đang cập nhật"
                    });
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Recommendation] Neo4j error for user-based/{userId}: {ex.Message}");
            }

            return Ok(recommendedCourses);
        }

        // 2. GỢI Ý DỰA TRÊN HỒ SƠ & NỘI DUNG (Content-Based + Popularity)
        [HttpGet("user-profile/{userId}")]
        public async Task<IActionResult> GetUserProfileBasedRecommendations(int userId)
        {
            Console.WriteLine($"[AI] Đang lấy gợi ý cá nhân hóa cho User: {userId}");
            var recommendedCourses = new List<object>();

            try
            {
                await using var session = _driver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));

                var query = @"
                    MERGE (nd:NguoiDung {id: $userId})
                    WITH nd
                    
                    // Lấy danh sách ID đã đăng ký hoặc đánh giá để loại trừ
                    OPTIONAL MATCH (nd)-[:DANG_KY|DANH_GIA]->(khExclude:KhoaHoc)
                    WITH nd, collect(DISTINCT khExclude.id) AS excludedCourseIds

                    // 1. Lấy khóa học từ Thể loại quan tâm (Interests)
                    OPTIONAL MATCH (nd)-[:QUAN_TAM]->(t:TheLoai)<-[:THUOC_THE_LOAI]-(khInterests:KhoaHoc)
                    WHERE NOT khInterests.id IN excludedCourseIds
                    WITH nd, excludedCourseIds, collect(DISTINCT khInterests) AS interestCourses

                    // 2. Lấy khóa học tương đồng với cái đã học (Content-Based)
                    OPTIONAL MATCH (nd)-[:DANG_KY|DANH_GIA]->(khHistory:KhoaHoc)-[:CONTENT_SIMILAR]-(khSim:KhoaHoc)
                    WHERE NOT khSim.id IN excludedCourseIds
                    WITH nd, interestCourses, excludedCourseIds, collect(DISTINCT khSim) AS similarCourses

                    // 3. Lấy tập ứng viên (Ưu tiên Interests)
                    WITH nd, interestCourses, excludedCourseIds
                    
                    OPTIONAL MATCH (khGlobal:KhoaHoc)
                    WHERE NOT khGlobal.id IN excludedCourseIds
                    WITH nd, interestCourses, khGlobal
                    LIMIT 100
                    WITH nd, interestCourses, collect(DISTINCT khGlobal) AS fallbackCourses
                    
                    UNWIND (CASE 
                        WHEN size(interestCourses) > 0 THEN interestCourses
                        ELSE fallbackCourses 
                    END) AS q
                    WITH DISTINCT nd, q
                    WHERE q IS NOT NULL
                    LIMIT 20

                    // 4. Tính điểm nhanh
                    OPTIONAL MATCH (nd)-[:QUAN_TAM]->(t:TheLoai)<-[:THUOC_THE_LOAI]-(q)
                    WITH q, (CASE WHEN t IS NOT NULL THEN 5.0 ELSE 0 END + COALESCE(q.tbdanhGia, 0)) AS finalScore

                    RETURN q.id AS CourseId, q.tieuDe AS Title, finalScore AS Score, 
                           0 AS TotalReviews, COALESCE(q.tbdanhGia, 0) AS AverageRating,
                           q.giaGoc AS OriginalPrice, q.urlAnh AS Image, 
                           'AI Recommendation' AS Instructor
                    ORDER BY Score DESC
                    LIMIT 12";

                var result = await session.RunAsync(query, new { userId });
                await result.ForEachAsync(record =>
                {
                    recommendedCourses.Add(new
                    {
                        CourseId = record["CourseId"].As<long>(),
                        Title = record["Title"]?.As<string>() ?? "Chưa có tiêu đề",
                        Score = record["Score"]?.As<double?>() ?? 0.0,
                        TotalReviews = record["TotalReviews"]?.As<long?>() ?? 0,
                        AverageRating = record["AverageRating"]?.As<double?>() ?? 0.0,
                        OriginalPrice = record["OriginalPrice"]?.As<double?>() ?? 0.0,
                        Image = record["Image"]?.As<string>() ?? "",
                        Instructor = record["Instructor"]?.As<string>() ?? "Đang cập nhật"
                    });
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Recommendation] Neo4j error for user-profile/{userId}: {ex.Message}");
            }

            return Ok(recommendedCourses);
        }

        // 3. GỢI Ý KHÓA HỌC TƯƠNG TỰ VỚI MỘT KHÓA HỌC CỤ THỂ (Item-Based Recommendation)
        [HttpGet("similar-course/{courseId}")]
        public async Task<IActionResult> GetSimilarCourses(int courseId)
        {
            var recommendedCourses = new List<object>();

            try
            {
                await using var session = _driver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));

                var query = @"
                    MATCH (khGoc:KhoaHoc {id: $courseId})-[rel:CONTENT_SIMILAR]-(q:KhoaHoc)
                    WHERE q.id <> $courseId

                    OPTIONAL MATCH (nd:NguoiDung)-[dg_q:DANH_GIA]->(q)
                    OPTIONAL MATCH (gv:GiangVien)-[:GIANG_DAY]->(q)

                    WITH q,
                        rel.score AS contentScore,
                        count(DISTINCT dg_q) AS soLuongDanhGia,
                        coalesce(q.danhGiaTrungBinh, 0.0) AS saoTrungBinh,
                        collect(DISTINCT gv.ten)[0] AS instructorName

                    WITH q, soLuongDanhGia, saoTrungBinh, instructorName,
                        q.giaGoc AS OriginalPrice,
                        q.urlAnh AS Image,
                        contentScore,
                        CASE
                        WHEN soLuongDanhGia = 0 THEN 0
                        ELSE log10(soLuongDanhGia + 1)
                        END AS popularityScore

                    WITH q, soLuongDanhGia, saoTrungBinh, instructorName, OriginalPrice, Image,
                        (contentScore * 0.5)
                        + ((saoTrungBinh / 5.0) * 0.25)
                        + (popularityScore * 0.25) AS simScore

                    ORDER BY simScore DESC
                    LIMIT 10

                    RETURN q.id AS CourseId,
                        q.tieuDe AS Title,
                        simScore AS Score,
                        soLuongDanhGia AS TotalReviews,
                        saoTrungBinh AS AverageRating,
                        OriginalPrice,
                        Image,
                        instructorName AS Instructor";

                var result = await session.RunAsync(query, new { courseId });
                await result.ForEachAsync(record =>
                {
                    recommendedCourses.Add(new
                    {
                        CourseId = record["CourseId"].As<long>(),
                        Title = record["Title"]?.As<string>() ?? "Chưa có tiêu đề",
                        Score = record["Score"]?.As<double?>() ?? 0.0,
                        TotalReviews = record["TotalReviews"]?.As<long?>() ?? 0,
                        AverageRating = record["AverageRating"]?.As<double?>() ?? 0.0,
                        OriginalPrice = record["OriginalPrice"]?.As<double?>() ?? 0.0,
                        Image = record["Image"]?.As<string>() ?? "",
                        Instructor = record["Instructor"]?.As<string>() ?? "Đang cập nhật"
                    });
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Recommendation] Neo4j error for similar-course/{courseId}: {ex.Message}");
            }

            return Ok(recommendedCourses);
        }

        // ③ POST /api/recommendations/sync-all — Đồng bộ lại toàn bộ dữ liệu sang Neo4j
        [Authorize(Roles = "Admin")]
        [HttpPost("sync-all")]
        public async Task<IActionResult> SyncAll()
        {
            try
            {
                // 1. Lấy dữ liệu từ SQL
                var categories = await _context.TheLoais.ToListAsync();
                var courses = await _context.KhoaHocs.ToListAsync();

                await using var session = _driver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));

                await session.ExecuteWriteAsync(async tx =>
                {
                    // 2. Sync Categories
                    foreach (var cat in categories)
                    {
                        await tx.RunAsync("MERGE (t:TheLoai {id: $id}) SET t.ten = $ten", 
                            new { id = cat.MaTheLoai, ten = cat.Ten });
                    }

                    // 3. Sync Courses
                    foreach (var kh in courses)
                    {
                        await tx.RunAsync("MERGE (kh:KhoaHoc {id: $id}) SET kh.tieuDe = $tieuDe, kh.urlAnh = $urlAnh, kh.giaGoc = $giaGoc", 
                            new { id = kh.MaKhoaHoc, tieuDe = kh.TieuDe, urlAnh = kh.AnhUrl, giaGoc = (double)(kh.GiaGoc ?? 0) });

                        // Link to Category
                        if (kh.MaTheLoai.HasValue)
                        {
                            await tx.RunAsync("MATCH (kh:KhoaHoc {id: $khId}), (t:TheLoai {id: $tId}) MERGE (kh)-[:THUOC_THE_LOAI]->(t)", 
                                new { khId = kh.MaKhoaHoc, tId = kh.MaTheLoai.Value });
                        }
                    }
                });

                return Ok(new { message = "Đồng bộ thành công!", categoriesCount = categories.Count, coursesCount = courses.Count });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[AI Error] {ex.Message}");
                return StatusCode(500, ex.Message);
            }
        }
    }
}