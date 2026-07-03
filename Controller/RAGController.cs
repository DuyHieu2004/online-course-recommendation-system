using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace online_course_recommendation_system.Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class RAGController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;

        public RAGController(IConfiguration configuration, HttpClient httpClient)
        {
            _configuration = configuration;
            _httpClient = httpClient;
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchAI([FromQuery] string query)
        {
            if (string.IsNullOrWhiteSpace(query))
                return BadRequest("Vui lòng nhập nội dung tìm kiếm.");

            try
            {
                // 1. TẠO VECTOR TỪ TRUY VẤN (Gọi sang Microservice Python nội bộ)
                var queryVector = await GetEmbeddingFromLocalServiceAsync(query);

                if (queryVector == null || queryVector.Count == 0)
                {
                    return StatusCode(500, "Lỗi khi tạo vector embedding cho truy vấn.");
                }

                // 2. CẤU HÌNH GỌI LÊN AZURE SEARCH
                var endpoint = _configuration["AzureSearch:Endpoint"];
                var apiKey = _configuration["AzureSearch:ApiKey"];
                var indexName = _configuration["AzureSearch:IndexName"];
                var semanticConfig = _configuration["AzureSearch:SemanticConfiguration"];

                var url = $"{endpoint}/indexes/{indexName}/docs/search?api-version=2024-11-01-preview";

                // 3. PAYLOAD CHÍNH XÁC NHƯ CODE PYTHON (CÓ VECTOR)
                var payload = new
                {
                    search = query,
                    vectorQueries = new[]
                    {
                        new
                        {
                            kind = "vector",
                            vector = queryVector, // Mảng float[] vừa lấy được
                            k = 10,
                            fields = "text_vector"
                        }
                    },
                    select = "MaKhoaHoc,TieuDe,ChunkText,GiaGoc,PhanTramTichCuc,SoDanhGiaTichCuc",
                    top = 10,
                    filter = "SoDanhGiaTichCuc gt 10",
                    queryType = "semantic",
                    semanticConfiguration = semanticConfig,
                    queryLanguage = "vi", 
                    queryRewrites = "generative"
                };

                var request = new HttpRequestMessage(HttpMethod.Post, url);
                request.Headers.Add("api-key", apiKey);
                request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

                var response = await _httpClient.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    var errorMsg = await response.Content.ReadAsStringAsync();
                    return StatusCode((int)response.StatusCode, $"Azure Search Error: {errorMsg}");
                }

                var jsonString = await response.Content.ReadAsStringAsync();
                var jsonDoc = JsonDocument.Parse(jsonString);
                var values = jsonDoc.RootElement.GetProperty("value").EnumerateArray().ToList();

                if (values.Count == 0) return Ok(new List<object>());

                // 4. CHUẨN HÓA VÀ SẮP XẾP LẠI (RE-RANKING) 50:50 NHƯ PYTHON
                var parsedResults = values.Select(v => new
                {
                    MaKhoaHoc = v.TryGetProperty("MaKhoaHoc", out var mkh) ? mkh.GetRawText().Replace("\"", "") : "",
                    TieuDe = v.TryGetProperty("TieuDe", out var td) ? td.GetString() : "Chưa có tiêu đề",
                    ChunkText = v.TryGetProperty("ChunkText", out var ct) ? ct.GetString() : "",
                    GiaGoc = v.TryGetProperty("GiaGoc", out var gg) ? gg.GetDouble() : 0,
                    PhanTramTichCuc = v.TryGetProperty("PhanTramTichCuc", out var pt) ? pt.GetDouble() : 0,
                    SoDanhGiaTichCuc = v.TryGetProperty("SoDanhGiaTichCuc", out var sdg) ? sdg.GetDouble() : 0
                }).ToList();

                double maxSoDanhGia = parsedResults.Max(x => x.SoDanhGiaTichCuc);
                double minSoDanhGia = parsedResults.Min(x => x.SoDanhGiaTichCuc);
                double maxPhanTram = parsedResults.Max(x => x.PhanTramTichCuc);
                double minPhanTram = parsedResults.Min(x => x.PhanTramTichCuc);

                var rankedResults = parsedResults.Select(r =>
                {
                    double normSoDanhGia = (maxSoDanhGia == minSoDanhGia) ? 1.0 : (r.SoDanhGiaTichCuc - minSoDanhGia) / (maxSoDanhGia - minSoDanhGia);
                    double normPhanTram = (maxPhanTram == minPhanTram) ? 1.0 : (r.PhanTramTichCuc - minPhanTram) / (maxPhanTram - minPhanTram);
                    
                    double customScore = (normSoDanhGia * 0.5) + (normPhanTram * 0.5);

                    return new
                    {
                        CourseId = long.TryParse(r.MaKhoaHoc, out long id) ? id : 0,
                        Title = r.TieuDe,
                        Description = r.ChunkText.Length > 200 ? r.ChunkText.Substring(0, 200) + "..." : r.ChunkText,
                        OriginalPrice = r.GiaGoc,
                        Score = customScore,
                        TotalReviews = (long)r.SoDanhGiaTichCuc,
                        AverageRating = (r.PhanTramTichCuc / 100.0) * 5.0, 
                        Image = "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=400&auto=format&fit=crop",
                        Instructor = "Trợ lý AI Gợi ý"
                    };
                })
                .OrderByDescending(r => r.Score)
                .ToList();

                return Ok(rankedResults);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[RAG Search] Error: {ex.Message}");
                return StatusCode(500, "Internal server error");
            }
        }

        // HÀM HỖ TRỢ: Lấy Vector từ API Python nội bộ (FastAPI)
        private async Task<List<float>> GetEmbeddingFromLocalServiceAsync(string text)
        {
            var embeddingApiUrl = _configuration["AzureSearch:EmbeddingApiUrl"];
            if (string.IsNullOrEmpty(embeddingApiUrl)) return new List<float>();

            var payload = new { text = text };
            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(embeddingApiUrl, content);
            if (!response.IsSuccessStatusCode)
            {
                var errorMsg = await response.Content.ReadAsStringAsync();
                throw new Exception($"Lỗi từ FastAPI Embedding Service: {errorMsg}");
            }

            var jsonString = await response.Content.ReadAsStringAsync();
            var jsonDoc = JsonDocument.Parse(jsonString);
            
            // Đọc mảng float từ JSON trả về
            var vectorArray = jsonDoc.RootElement.GetProperty("vector").EnumerateArray();
            return vectorArray.Select(x => x.GetSingle()).ToList();
        }
    }
}