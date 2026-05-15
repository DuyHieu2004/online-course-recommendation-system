using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Neo4j.Driver;
using online_course_recommendation_system.Configurations;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace online_course_recommendation_system.Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendationController : ControllerBase
    {
        private readonly IDriver _driver;
        private readonly Neo4jSettings _neo4jSettings;
        
        public RecommendationController(
            IDriver driver,
            IOptions<Neo4jSettings> neo4jOptions)
        {
            _driver = driver;
            _neo4jSettings = neo4jOptions.Value;
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
            var recommendedCourses = new List<object>();

            try
            {
                await using var session = _driver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));

                var query = @"
                    MATCH (nd:NguoiDung {id: $userId})-[:DANH_GIA]->(khDaHoc:KhoaHoc)
                    WITH collect(khDaHoc.id) AS ratedCourseIds

                    MATCH (nd:NguoiDung {id: $userId})-[dg:DANH_GIA]->(kh:KhoaHoc)
                    WITH ratedCourseIds, kh, (dg.diem / 5.0) AS normalizedRating
                    ORDER BY normalizedRating DESC
                    LIMIT 5

                    MATCH (kh)-[rel:CONTENT_SIMILAR]-(q:KhoaHoc)
                    WHERE NOT q.id IN ratedCourseIds

                    OPTIONAL MATCH (aiDo:NguoiDung)-[dg_q:DANH_GIA]->(q)
                    OPTIONAL MATCH (gv:GiangVien)-[:GIANG_DAY]->(q)
                    WITH q, 
                         rel.score AS contentScore, 
                         normalizedRating, 
                         count(dg_q) AS soLuongDanhGia, 
                         q.danhGiaTrungBinh AS saoTrungBinh,
                         collect(gv.ten)[0] AS instructorName
                    WHERE soLuongDanhGia > 0 

                    WITH q, soLuongDanhGia, saoTrungBinh, instructorName,
                         (contentScore * 0.4) + (normalizedRating * 0.2) + ((saoTrungBinh / 5.0) * 0.2) + (log10(soLuongDanhGia + 1) * 0.2) AS simScore

                    WITH q.id AS CourseId, q.tieuDe AS Title, max(simScore) AS FinalScore, 
                         soLuongDanhGia, saoTrungBinh, q.giaGoc AS OriginalPrice, 
                         q.urlAnh AS Image, instructorName AS Instructor
                    
                    ORDER BY FinalScore DESC
                    LIMIT 10
                    
                    RETURN CourseId, Title, FinalScore AS Score, soLuongDanhGia AS TotalReviews, saoTrungBinh AS AverageRating,
                           OriginalPrice, Image, Instructor";

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
    }
}