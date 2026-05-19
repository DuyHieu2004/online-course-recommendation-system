using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class CartController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CartController(AppDbContext context)
        {
            _context = context;
        }

        // ① GET /api/cart — Lấy giỏ hàng hiện tại
        [HttpGet]
        public async Task<IActionResult> GetCart()
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var cart = await _context.GioHangs
                .Include(g => g.ChiTietGioHangs)
                    .ThenInclude(ct => ct.MaKhoaHocNavigation)
                        .ThenInclude(k => k!.MaTheLoaiNavigation)
                .Include(g => g.ChiTietGioHangs)
                    .ThenInclude(ct => ct.MaKhoaHocNavigation)
                        .ThenInclude(k => k!.MaKhuyenMaiNavigation)
                .Include(g => g.ChiTietGioHangs)
                    .ThenInclude(ct => ct.MaKhoaHocNavigation)
                        .ThenInclude(k => k!.GiangVienKhoaHocs)
                            .ThenInclude(gv => gv.MaGiangVienNavigation)
                .Where(g => g.MaNguoiDung == userId.Value)
                .OrderByDescending(g => g.NgayTao)
                .FirstOrDefaultAsync();

            if (cart == null)
            {
                return Ok(new { items = Array.Empty<object>(), tongTien = 0 });
            }

            var items = cart.ChiTietGioHangs.Select(ct => new
            {
                ct.MaChiTietGioHang,
                ct.Gia,
                KhoaHoc = ct.MaKhoaHocNavigation == null ? null : new
                {
                    ct.MaKhoaHocNavigation.MaKhoaHoc,
                    ct.MaKhoaHocNavigation.TieuDe,
                    ct.MaKhoaHocNavigation.GiaGoc,
                    ct.MaKhoaHocNavigation.AnhUrl,
                    ct.MaKhoaHocNavigation.TbdanhGia,
                    TheLoai = ct.MaKhoaHocNavigation.MaTheLoaiNavigation?.Ten,
                    GiangVien = ct.MaKhoaHocNavigation.GiangVienKhoaHocs
                        .Where(gv => gv.LaGiangVienChinh == true)
                        .Select(gv => gv.MaGiangVienNavigation.Ten)
                        .FirstOrDefault(),

                    MaKhuyenMaiNavigation = ct.MaKhoaHocNavigation.MaKhuyenMaiNavigation != null ? new {
                        ct.MaKhoaHocNavigation.MaKhuyenMaiNavigation.PhanTramGiam,
                        ct.MaKhoaHocNavigation.MaKhuyenMaiNavigation.NgayKetThuc
                    } : null
                }
            }).ToList();

            var tongTien = items.Sum(i => {
                decimal giaGoc = i.KhoaHoc?.GiaGoc ?? 0;
                var km = i.KhoaHoc?.MaKhuyenMaiNavigation;
                
                // Kiểm tra nếu có khuyến mãi và chưa hết hạn
                if (km != null && km.NgayKetThuc >= DateTime.Now) {
                    // Tính giá sau khi giảm
                    return giaGoc * (1m - (decimal)(km.PhanTramGiam / 100.0));
                }
                return giaGoc;
            });

            return Ok(new { items, tongTien });
        }

        // ② POST /api/cart/{courseId} — Thêm khóa học vào giỏ
        [HttpPost("{courseId}")]
        public async Task<IActionResult> AddToCart(int courseId)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            // Kiểm tra khóa học tồn tại
            var course = await _context.KhoaHocs.FindAsync(courseId);
            if (course == null)
                return NotFound(new { message = "Không tìm thấy khóa học." });

            // Tìm hoặc tạo giỏ hàng
            var cart = await _context.GioHangs
                .Include(g => g.ChiTietGioHangs)
                .FirstOrDefaultAsync(g => g.MaNguoiDung == userId.Value);

            if (cart == null)
            {
                cart = new GioHang
                {
                    MaNguoiDung = userId.Value,
                    NgayTao = DateTime.Now
                };
                _context.GioHangs.Add(cart);
                await _context.SaveChangesAsync();
            }

            // Kiểm tra đã có trong giỏ chưa
            if (cart.ChiTietGioHangs.Any(ct => ct.MaKhoaHoc == courseId))
                return BadRequest(new { message = "Khóa học đã có trong giỏ hàng." });

            // Kiểm tra đã mua (đã đăng ký học) chưa
            var enrollment = await _context.TienDos
                .FirstOrDefaultAsync(t => t.MaNguoiDung == userId.Value && t.MaKhoaHoc == courseId);

            if (enrollment != null)
            {
                if (enrollment.NgayKetThuc.HasValue && enrollment.NgayKetThuc.Value < DateTime.Now)
                {
                    // Khóa học đã hết hạn -> Cho phép mua tiếp (Đi tiếp xuống dưới)
                }
                else
                {
                    // Vẫn còn hạn -> Không cho mua
                    return BadRequest(new { message = "Bạn đã sở hữu khóa học này và vẫn đang còn hạn sử dụng." });
                }
            }

            var cartItem = new ChiTietGioHang
            {
                MaGioHang = cart.MaGioHang,
                MaKhoaHoc = courseId,
                Gia = course.GiaGoc
            };

            _context.ChiTietGioHangs.Add(cartItem);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                var innerMsg = ex.InnerException?.Message ?? ex.Message;
                if (innerMsg.Contains("sở hữu") || innerMsg.Contains("khóa học này"))
                    return BadRequest(new { message = "Bạn đã sở hữu khóa học này, không thể thêm vào giỏ hàng." });
                return BadRequest(new { message = innerMsg });
            }

            return Ok(new { message = "Đã thêm vào giỏ hàng!", maChiTietGioHang = cartItem.MaChiTietGioHang });
        }

        // ③ DELETE /api/cart/{courseId} — Xóa khóa học khỏi giỏ
        [HttpDelete("{courseId}")]
        public async Task<IActionResult> RemoveFromCart(int courseId)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var cart = await _context.GioHangs
                .Include(g => g.ChiTietGioHangs)
                .FirstOrDefaultAsync(g => g.MaNguoiDung == userId.Value);

            if (cart == null)
                return NotFound(new { message = "Giỏ hàng trống." });

            var item = cart.ChiTietGioHangs.FirstOrDefault(ct => ct.MaKhoaHoc == courseId);
            if (item == null)
                return NotFound(new { message = "Khóa học không có trong giỏ hàng." });

            _context.ChiTietGioHangs.Remove(item);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa khỏi giỏ hàng." });
        }

        private int? GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
                return userId;
            return null;
        }
    }
}
