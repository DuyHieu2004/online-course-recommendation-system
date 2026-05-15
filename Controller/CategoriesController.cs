using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.DTO;
using online_course_recommendation_system.Models;
using Neo4j.Driver;
using online_course_recommendation_system.Configurations;
using Microsoft.Extensions.Options;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoriesController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IDriver _neo4jDriver;
        private readonly Neo4jSettings _neo4jSettings;

        public CategoriesController(AppDbContext context, IDriver neo4jDriver, IOptions<Neo4jSettings> neo4jOptions)
        {
            _context = context;
            _neo4jDriver = neo4jDriver;
            _neo4jSettings = neo4jOptions.Value;
        }

        // ① GET /api/categories — Lấy tất cả danh mục (Phân trang)
        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 100,
            [FromQuery] string? search = null)
        {
            var query = _context.TheLoais.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                query = query.Where(c => c.Ten.Contains(search));
            }

            var totalCount = await query.CountAsync();

            var categories = await query
                .OrderBy(c => c.MaTheLoai)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(c => new
                {
                    c.MaTheLoai,
                    c.Ten,
                    c.MoTa,
                    SoKhoaHoc = c.KhoaHocs.Count
                })
                .ToListAsync();

            return Ok(new
            {
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling((double)totalCount / pageSize),
                data = categories
            });
        }

        // ② GET /api/categories/{id} — Chi tiết 1 danh mục (Public)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var category = await _context.TheLoais
                .Where(c => c.MaTheLoai == id)
                .Select(c => new
                {
                    c.MaTheLoai,
                    c.Ten,
                    c.MoTa,
                    SoKhoaHoc = c.KhoaHocs.Count
                })
                .FirstOrDefaultAsync();

            if (category == null)
                return NotFound(new { message = "Không tìm thấy danh mục." });

            return Ok(category);
        }

        // ③ POST /api/categories — Tạo danh mục mới (Admin)
        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CategoryDto request)
        {
            // Kiểm tra trùng tên
            if (await _context.TheLoais.AnyAsync(c => c.Ten == request.Ten))
                return BadRequest(new { message = "Tên danh mục đã tồn tại." });

            var category = new TheLoai
            {
                Ten = request.Ten,
                MoTa = request.MoTa
            };

            _context.TheLoais.Add(category);
            await _context.SaveChangesAsync();

            // Sync to Neo4j
            var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
            try {
                await session.ExecuteWriteAsync(async tx => {
                    await tx.RunAsync("MERGE (t:TheLoai {id: $id}) SET t.ten = $ten", 
                        new { id = category.MaTheLoai, ten = category.Ten });
                });
            } finally {
                await session.CloseAsync();
            }

            return Ok(new
            {
                message = "Tạo danh mục thành công!",
                data = new { category.MaTheLoai, category.Ten, category.MoTa }
            });
        }

        // ④ PUT /api/categories/{id} — Cập nhật danh mục (Admin)
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] CategoryDto request)
        {
            var category = await _context.TheLoais.FindAsync(id);
            if (category == null)
                return NotFound(new { message = "Không tìm thấy danh mục." });

            // Kiểm tra trùng tên với danh mục khác
            if (await _context.TheLoais.AnyAsync(c => c.Ten == request.Ten && c.MaTheLoai != id))
                return BadRequest(new { message = "Tên danh mục đã tồn tại." });

            category.Ten = request.Ten;
            category.MoTa = request.MoTa;
            await _context.SaveChangesAsync();

            // Sync to Neo4j
            var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
            try {
                await session.ExecuteWriteAsync(async tx => {
                    await tx.RunAsync("MERGE (t:TheLoai {id: $id}) SET t.ten = $ten", 
                        new { id = category.MaTheLoai, ten = category.Ten });
                });
            } finally {
                await session.CloseAsync();
            }

            return Ok(new
            {
                message = "Cập nhật danh mục thành công!",
                data = new { category.MaTheLoai, category.Ten, category.MoTa }
            });
        }

        // ⑤ DELETE /api/categories/{id} — Xóa danh mục (Admin, chỉ khi không có khóa học)
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var category = await _context.TheLoais
                .Include(c => c.KhoaHocs)
                .FirstOrDefaultAsync(c => c.MaTheLoai == id);

            if (category == null)
                return NotFound(new { message = "Không tìm thấy danh mục." });

            if (category.KhoaHocs.Any())
                return BadRequest(new { message = $"Không thể xóa. Danh mục '{category.Ten}' đang có {category.KhoaHocs.Count} khóa học." });

            _context.TheLoais.Remove(category);
            await _context.SaveChangesAsync();

            // Sync to Neo4j
            try {
                var session = _neo4jDriver.AsyncSession(o => o.WithDatabase(_neo4jSettings.Database));
                try {
                    await session.ExecuteWriteAsync(async tx => {
                        await tx.RunAsync("MATCH (t:TheLoai {id: $id}) DETACH DELETE t", new { id = id });
                    });
                } finally {
                    await session.CloseAsync();
                }
            } catch (Exception neoEx) {
                Console.WriteLine($"[Neo4j Sync Error] Failed to delete category from Neo4j {id}: {neoEx.Message}");
            }

            return Ok(new { message = $"Đã xóa danh mục '{category.Ten}'." });
        }
    }
}
