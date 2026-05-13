using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.DTO;
using online_course_recommendation_system.Models;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class PromotionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PromotionsController(AppDbContext context)
        {
            _context = context;
        }

        // ① GET /api/promotions — Lấy tất cả khuyến mãi (Phân trang)
        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? search = null)
        {
            var query = _context.KhuyenMais.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                query = query.Where(km => km.TenChuongTrinh.Contains(search));
            }

            var totalCount = await query.CountAsync();

            var promotions = await query
                .OrderByDescending(km => km.NgayBatDau)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(km => new
                {
                    km.MaKhuyenMai,
                    km.TenChuongTrinh,
                    km.PhanTramGiam,
                    km.NgayBatDau,
                    km.NgayKetThuc,
                    SoKhoaHoc = km.KhoaHocs.Count,
                    TinhTrang = km.NgayKetThuc != null && km.NgayKetThuc < DateTime.Now
                        ? "expired" : "active"
                })
                .ToListAsync();

            return Ok(new
            {
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling((double)totalCount / pageSize),
                data = promotions
            });
        }

        // ② GET /api/promotions/{id} — Chi tiết 1 khuyến mãi
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var promo = await _context.KhuyenMais
                .Where(km => km.MaKhuyenMai == id)
                .Select(km => new
                {
                    km.MaKhuyenMai,
                    km.TenChuongTrinh,
                    km.PhanTramGiam,
                    km.NgayBatDau,
                    km.NgayKetThuc,
                    SoKhoaHoc = km.KhoaHocs.Count,
                    TinhTrang = km.NgayKetThuc != null && km.NgayKetThuc < DateTime.Now
                        ? "expired" : "active"
                })
                .FirstOrDefaultAsync();

            if (promo == null)
                return NotFound(new { message = "Không tìm thấy khuyến mãi." });

            return Ok(promo);
        }

        // ③ POST /api/promotions — Tạo khuyến mãi mới
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] PromotionDto request)
        {
            if (string.IsNullOrWhiteSpace(request.TenChuongTrinh))
                return BadRequest(new { message = "Tên chương trình không được để trống." });

            var promo = new KhuyenMai
            {
                TenChuongTrinh = request.TenChuongTrinh,
                PhanTramGiam = request.PhanTramGiam,
                NgayBatDau = request.NgayBatDau ?? DateTime.Now,
                NgayKetThuc = request.NgayKetThuc
            };

            _context.KhuyenMais.Add(promo);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Tạo khuyến mãi thành công!",
                data = new
                {
                    promo.MaKhuyenMai,
                    promo.TenChuongTrinh,
                    promo.PhanTramGiam,
                    promo.NgayBatDau,
                    promo.NgayKetThuc
                }
            });
        }

        // ④ PUT /api/promotions/{id} — Cập nhật khuyến mãi
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] PromotionDto request)
        {
            var promo = await _context.KhuyenMais.FindAsync(id);
            if (promo == null)
                return NotFound(new { message = "Không tìm thấy khuyến mãi." });

            if (!string.IsNullOrWhiteSpace(request.TenChuongTrinh))
                promo.TenChuongTrinh = request.TenChuongTrinh;
            if (request.PhanTramGiam.HasValue)
                promo.PhanTramGiam = request.PhanTramGiam;
            if (request.NgayBatDau.HasValue)
                promo.NgayBatDau = request.NgayBatDau;
            if (request.NgayKetThuc.HasValue)
                promo.NgayKetThuc = request.NgayKetThuc;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật khuyến mãi thành công!",
                data = new
                {
                    promo.MaKhuyenMai,
                    promo.TenChuongTrinh,
                    promo.PhanTramGiam,
                    promo.NgayBatDau,
                    promo.NgayKetThuc
                }
            });
        }

        // ⑤ DELETE /api/promotions/{id} — Xóa khuyến mãi
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var promo = await _context.KhuyenMais
                .Include(km => km.KhoaHocs)
                .FirstOrDefaultAsync(km => km.MaKhuyenMai == id);

            if (promo == null)
                return NotFound(new { message = "Không tìm thấy khuyến mãi." });

            if (promo.KhoaHocs.Any())
                return BadRequest(new { message = $"Không thể xóa. Khuyến mãi '{promo.TenChuongTrinh}' đang gắn với {promo.KhoaHocs.Count} khóa học." });

            _context.KhuyenMais.Remove(promo);
            await _context.SaveChangesAsync();

            return Ok(new { message = $"Đã xóa khuyến mãi '{promo.TenChuongTrinh}'." });
        }

        // Thêm Endpoint này vào trong PromotionsController
        [HttpPost("{id}/apply")]
        public async Task<IActionResult> ApplyPromotion(int id, [FromBody] PromotionDto request)
        {
            var promo = await _context.KhuyenMais.FindAsync(id);
            if (promo == null)
                return NotFound(new { message = "Không tìm thấy khuyến mãi." });

            // Lấy tất cả khóa học đang được áp dụng khuyến mãi này (để reset nếu cần)
            var currentCourses = await _context.KhoaHocs.Where(k => k.MaKhuyenMai == id).ToListAsync();
            foreach (var c in currentCourses)
            {
                c.MaKhuyenMai = null; // Tạm thời gỡ bỏ hết
            }

            // Tìm các khóa học mới cần áp dụng (theo ID khóa học HOẶC theo ID Thể loại)
            var coursesToApply = await _context.KhoaHocs
                .Where(k => request.CourseIds.Contains(k.MaKhoaHoc) || 
                        (k.MaTheLoai.HasValue && request.CategoryIds.Contains(k.MaTheLoai.Value)))
                .ToListAsync();

            // Gắn khuyến mãi
            foreach (var c in coursesToApply)
            {
                c.MaKhuyenMai = id;
            }

            await _context.SaveChangesAsync();

            return Ok(new { 
                message = $"Đã áp dụng khuyến mãi cho {coursesToApply.Count} khóa học.",
                appliedCount = coursesToApply.Count 
            });
        }
    }
}
