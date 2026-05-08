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
    public class OrdersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OrdersController(AppDbContext context)
        {
            _context = context;
        }

        // ① POST /api/orders/checkout — Thanh toán giỏ hàng
        [HttpPost("checkout")]
        public async Task<IActionResult> Checkout([FromBody] CheckoutRequest? request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            try
            {

            var cart = await _context.GioHangs
                .Include(g => g.ChiTietGioHangs)
                    .ThenInclude(ct => ct.MaKhoaHocNavigation)
                .FirstOrDefaultAsync(g => g.MaNguoiDung == userId.Value);

            if (cart == null || !cart.ChiTietGioHangs.Any())
                return BadRequest(new { message = "Giỏ hàng trống." });

            // Tạo hóa đơn
            var hoaDon = new HoaDon
            {
                MaNguoiDung = userId.Value,
                TongTien = 0,
                PhuongThucThanhToan = request?.PhuongThucThanhToan ?? "Chuyển khoản",
                TinhTrangThanhToan = true,
                NgayTao = DateTime.Now
            };

            _context.HoaDons.Add(hoaDon);
            await _context.SaveChangesAsync();

            // Tạo chi tiết hóa đơn + tạo tiến độ học
            decimal tongTien = 0;
            foreach (var item in cart.ChiTietGioHangs)
            {
                var gia = item.Gia ?? item.MaKhoaHocNavigation?.GiaGoc ?? 0;
                tongTien += gia;

                _context.ChiTietHoaDons.Add(new ChiTietHoaDon
                {
                    MaHoaDon = hoaDon.MaHoaDon,
                    MaKhoaHoc = item.MaKhoaHoc,
                    Gia = gia
                });

                // Tạo bản ghi tiến độ (đăng ký khóa học)
                if (item.MaKhoaHoc.HasValue)
                {
                    var alreadyEnrolled = await _context.TienDos
                        .AnyAsync(t => t.MaNguoiDung == userId.Value && t.MaKhoaHoc == item.MaKhoaHoc);

                    if (!alreadyEnrolled)
                    {
                        var thoiGianHoc = item.MaKhoaHocNavigation?.ThoiGianHocDuKien ?? 0;
                        var thoiGianTre = item.MaKhoaHocNavigation?.ThoiGianChoPhepTre ?? 0;
                        DateTime? ngayKetThuc = null;
                        if (thoiGianHoc > 0)
                        {
                            ngayKetThuc = DateTime.Now.AddMonths(thoiGianHoc).AddDays(thoiGianTre);
                        }

                        _context.TienDos.Add(new TienDo
                        {
                            MaNguoiDung = userId.Value,
                            MaKhoaHoc = item.MaKhoaHoc,
                            PhanTramTienDo = 0,
                            TinhTrang = true,
                            NgayThamGia = DateTime.Now,
                            NgayKetThuc = ngayKetThuc
                        });
                    }
                }
            }

            hoaDon.TongTien = tongTien;

            // Xóa giỏ hàng
            _context.ChiTietGioHangs.RemoveRange(cart.ChiTietGioHangs);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Thanh toán thành công!",
                maHoaDon = hoaDon.MaHoaDon,
                tongTien = hoaDon.TongTien
            });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.InnerException != null ? ex.InnerException.Message : ex.Message });
            }
        }

        // ② GET /api/orders — Lịch sử đơn hàng
        [HttpGet]
        public async Task<IActionResult> GetOrders(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? search = null,
            [FromQuery] string? status = null)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var query = _context.HoaDons
                .Where(h => h.MaNguoiDung == userId.Value)
                .Include(h => h.ChiTietHoaDons)
                    .ThenInclude(ct => ct.MaKhoaHocNavigation)
                .AsQueryable();

            // Lọc theo trạng thái
            if (!string.IsNullOrEmpty(status))
            {
                if (status == "Đã thanh toán")
                    query = query.Where(h => h.TinhTrangThanhToan == true);
                else if (status == "Thất bại")
                    query = query.Where(h => h.TinhTrangThanhToan == false);
                else if (status == "Chờ thanh toán")
                    query = query.Where(h => h.TinhTrangThanhToan == null);
            }

            // Lọc theo từ khóa tìm kiếm (Mã hóa đơn hoặc Tên khóa học)
            if (!string.IsNullOrEmpty(search))
            {
                if (int.TryParse(search, out int maHD))
                {
                    query = query.Where(h => h.MaHoaDon == maHD);
                }
                else
                {
                    query = query.Where(h => h.ChiTietHoaDons.Any(ct => ct.MaKhoaHocNavigation.TieuDe.Contains(search)));
                }
            }

            var totalCount = await query.CountAsync();

            var orders = await query
                .OrderByDescending(h => h.NgayTao)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(h => new
                {
                    h.MaHoaDon,
                    h.TongTien,
                    h.PhuongThucThanhToan,
                    TinhTrangThanhToan = h.TinhTrangThanhToan == true ? "Đã thanh toán" : (h.TinhTrangThanhToan == false ? "Thất bại" : "Chờ thanh toán"),
                    h.NgayTao,
                    ChiTiet = h.ChiTietHoaDons.Select(ct => new
                    {
                        ct.MaChiTietHoaDon,
                        ct.Gia,
                        KhoaHoc = ct.MaKhoaHocNavigation == null ? null : new
                        {
                            ct.MaKhoaHocNavigation.MaKhoaHoc,
                            ct.MaKhoaHocNavigation.TieuDe,
                            ct.MaKhoaHocNavigation.AnhUrl,
                            ct.MaKhoaHocNavigation.ThoiGianHocDuKien,
                            ct.MaKhoaHocNavigation.ThoiGianChoPhepTre
                        }
                    })
                })
                .ToListAsync();

            return Ok(new { totalCount, page, pageSize, data = orders });
        }

        private int? GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
                return userId;
            return null;
        }
    }

    public class CheckoutRequest
    {
        public string? PhuongThucThanhToan { get; set; }
    }
}
