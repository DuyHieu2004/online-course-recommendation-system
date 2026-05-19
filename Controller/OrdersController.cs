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

        // ① POST /api/orders/checkout — Thanh toán giỏ hàng (Có áp dụng Giảm giá Admin & Voucher)
        [HttpPost("checkout")]
        public async Task<IActionResult> Checkout([FromBody] CheckoutRequest? request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            // 1. TẠO TRANSACTION ĐỂ ĐẢM BẢO AN TOÀN DỮ LIỆU
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var user = await _context.NguoiDungs.FindAsync(userId.Value);
                if (user == null) return NotFound(new { message = "Người dùng không tồn tại." });

                // Lấy giỏ hàng KÈM THEO KHUYẾN MÃI CỦA ADMIN
                var cart = await _context.GioHangs
                    .Include(g => g.ChiTietGioHangs)
                        .ThenInclude(ct => ct.MaKhoaHocNavigation)
                            .ThenInclude(k => k.MaKhuyenMaiNavigation) // Lấy KM Admin
                    .FirstOrDefaultAsync(g => g.MaNguoiDung == userId.Value);

                if (cart == null || !cart.ChiTietGioHangs.Any())
                    return BadRequest(new { message = "Giỏ hàng trống." });

                // 2. KIỂM TRA MÃ GIẢM GIÁ (VOUCHER CỦA USER) & GIỚI HẠN 5 LẦN/NGÀY
                decimal phanTramVoucher = 0;
                if (!string.IsNullOrEmpty(request?.MaVoucher))
                {
                    // Check giới hạn dùng 5 mã/ngày
                    var usagesToday = await _context.HoaDons
                        .CountAsync(h => h.MaNguoiDung == userId.Value && h.MaVoucher != null && h.NgayTao.Value.Date == DateTime.Now.Date);
                    
                    if (usagesToday >= 5)
                        return BadRequest(new { message = "Bạn đã sử dụng tối đa 5 mã giảm giá trong hôm nay." });

                    var voucher = await _context.VoucherHangs.FirstOrDefaultAsync(v => v.MaCode == request.MaVoucher);
                    if (voucher == null) 
                        return BadRequest(new { message = "Mã giảm giá không hợp lệ hoặc không tồn tại." });

                    // Validate Voucher có đúng với Hạng của User không
                    var hangCuaVoucher = await _context.HangThanhViens.FindAsync(voucher.MaHang);
                    if (hangCuaVoucher == null || hangCuaVoucher.TenHang != user.HangThanhVien)
                        return BadRequest(new { message = $"Mã giảm giá này đặc quyền dành riêng cho hạng {hangCuaVoucher?.TenHang}." });

                    phanTramVoucher = (decimal)hangCuaVoucher.PhanTramUuDai;
                }

                // 3. TẠO HÓA ĐƠN TRƯỚC (Để lấy MaHoaDon)
                var hoaDon = new HoaDon
                {
                    MaNguoiDung = userId.Value,
                    TongTien = 0, // Sẽ tính chính xác ở dưới
                    PhuongThucThanhToan = request?.PhuongThucThanhToan ?? "Chuyển khoản",
                    TinhTrangThanhToan = true,
                    NgayTao = DateTime.Now,
                    MaVoucher = request?.MaVoucher,
                    SoTienGiam = 0
                };
                _context.HoaDons.Add(hoaDon);
                await _context.SaveChangesAsync();

                // 4. TÍNH TOÁN TIỀN VÀ THÊM VÀO CHI TIẾT HÓA ĐƠN
                decimal tongTienTamTinh = 0; // Tổng tiền sau khi trừ KM Admin

                foreach (var item in cart.ChiTietGioHangs)
                {
                    var course = item.MaKhoaHocNavigation;
                    if (course == null) continue;

                    decimal giaThucTe = course.GiaGoc ?? 0;

                    // Trừ phần trăm Khuyến mãi của Admin (Nếu có đợt giảm giá)
                    if (course.MaKhuyenMaiNavigation != null && course.MaKhuyenMaiNavigation.NgayKetThuc >= DateTime.Now)
                    {
                        decimal phanTramAdmin = (decimal)(course.MaKhuyenMaiNavigation.PhanTramGiam ?? 0);
                        giaThucTe = giaThucTe * (1m - (phanTramAdmin / 100m));
                    }

                    tongTienTamTinh += giaThucTe;

                    // Ghi nhận giá đã giảm của Admin vào DB
                    _context.ChiTietHoaDons.Add(new ChiTietHoaDon
                    {
                        MaHoaDon = hoaDon.MaHoaDon,
                        MaKhoaHoc = item.MaKhoaHoc,
                        Gia = giaThucTe 
                    });

                    // Logic thêm Tiến Độ / Gia Hạn (Giữ nguyên của bạn)
                    var existingTienDo = await _context.TienDos.FirstOrDefaultAsync(t => t.MaNguoiDung == userId.Value && t.MaKhoaHoc == item.MaKhoaHoc);
                    var thoiGianHoc = course.ThoiGianHocDuKien ?? 0;
                    var thoiGianTre = course.ThoiGianChoPhepTre ?? 0;
                    DateTime? ngayKetThucMoi = thoiGianHoc > 0 ? DateTime.Now.AddMonths(thoiGianHoc).AddDays(thoiGianTre) : null;

                    if (existingTienDo != null)
                    {
                        existingTienDo.NgayKetThuc = ngayKetThucMoi;
                        existingTienDo.TinhTrang = true;
                        existingTienDo.NgayThamGia = DateTime.Now; 
                    }
                    else
                    {
                        _context.TienDos.Add(new TienDo { MaNguoiDung = userId.Value, MaKhoaHoc = item.MaKhoaHoc, PhanTramTienDo = 0, TinhTrang = true, NgayThamGia = DateTime.Now, NgayKetThuc = ngayKetThucMoi });
                    }
                }

                // 5. TRỪ TIẾP VOUCHER CỦA USER VÀ LƯU TỔNG TIỀN CUỐI CÙNG
                decimal soTienGiamVoucher = tongTienTamTinh * (phanTramVoucher / 100m);
                hoaDon.SoTienGiam = Math.Round(soTienGiamVoucher, 0); // Làm tròn tiền
                hoaDon.TongTien = Math.Max(0, tongTienTamTinh - hoaDon.SoTienGiam.Value); 
                
                _context.ChiTietGioHangs.RemoveRange(cart.ChiTietGioHangs);
                await _context.SaveChangesAsync();

                // 6. LOGIC TỰ ĐỘNG THĂNG HẠNG VÀ TẶNG VOUCHER (ĐÃ KHẮC PHỤC TRIỆT ĐỂ)
                int totalCourses = await _context.TienDos.CountAsync(t => t.MaNguoiDung == userId.Value);
                
                // Lấy toàn bộ danh sách hạng xếp từ cao xuống thấp
                var danhSachHang = await _context.HangThanhViens.OrderByDescending(h => h.SoKhoaHocToiThieu).ToListAsync();
                
                // Hạng cao nhất mà user ĐỦ ĐIỀU KIỆN đạt được ở hiện tại
                var matchedTier = danhSachHang.FirstOrDefault(h => totalCourses >= h.SoKhoaHocToiThieu);

                // Lấy thông tin Hạng HIỆN TẠI của user (Xử lý triệt để lỗi NULL với tài khoản cũ)
                string currentTierName = string.IsNullOrEmpty(user.HangThanhVien) ? "Thường" : user.HangThanhVien;
                var currentTier = danhSachHang.FirstOrDefault(h => h.TenHang == currentTierName);

                // ĐIỀU KIỆN VÀNG: Chỉ thăng hạng khi Hạng Mới có yêu cầu số khóa học > Hạng Hiện Tại
                if (matchedTier != null && currentTier != null && matchedTier.SoKhoaHocToiThieu > currentTier.SoKhoaHocToiThieu)
                {
                    user.HangThanhVien = matchedTier.TenHang; // Cập nhật hạng mới
                    
                    var voucherThuong = await _context.VoucherHangs.FirstOrDefaultAsync(v => v.MaHang == matchedTier.MaHang);
                    
                    string noiDungThongBao = voucherThuong != null
                        ? $"Chúc mừng bạn đã sở hữu {totalCourses} khóa học. Tặng bạn mã giảm giá {matchedTier.PhanTramUuDai}%: {voucherThuong.MaCode}. Mã có thể dùng 5 lần/ngày!"
                        : $"Chúc mừng bạn đã sở hữu {totalCourses} khóa học. Bạn đã kích hoạt đặc quyền ưu đãi giảm {matchedTier.PhanTramUuDai}% cho các đơn hàng tiếp theo!";

                    _context.ThongBaos.Add(new ThongBao
                    {
                        MaNguoiDung = userId.Value,
                        TieuDe = $"🎉 Bạn đã được thăng hạng {matchedTier.TenHang}!",
                        NoiDung = noiDungThongBao,
                        NgayTao = DateTime.Now,
                        DaDoc = false
                    });
                }
                else if (string.IsNullOrEmpty(user.HangThanhVien))
                {
                    // Âm thầm chuẩn hóa dữ liệu cho các tài khoản cũ bị NULL về mốc cơ sở
                    user.HangThanhVien = "Thường"; 
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new
                {
                    message = "Thanh toán thành công!",
                    maHoaDon = hoaDon.MaHoaDon,
                    tongTien = hoaDon.TongTien,
                    soTienGiam = hoaDon.SoTienGiam
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
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

        // ③ GET /api/orders/my-tier — Lấy thông tin hạng thành viên của user
        [HttpGet("my-tier")]
        public async Task<IActionResult> GetMyTier()
        {
            var userId = GetUserIdFromToken();
            if (userId == null)
                return Unauthorized(new { message = "Token không hợp lệ." });

            var user = await _context.NguoiDungs.FindAsync(userId.Value);
            int totalCourses = await _context.TienDos.CountAsync(t => t.MaNguoiDung == userId.Value);
            
            var tatCaHang = await _context.HangThanhViens.OrderBy(h => h.SoKhoaHocToiThieu).ToListAsync();

            return Ok(new
            {
                hangHienTai = user?.HangThanhVien ?? "Thường",
                soKhoaHocDaMua = totalCourses,
                chiTietCacHang = tatCaHang.Select(h => new { h.TenHang, h.SoKhoaHocToiThieu, h.PhanTramUuDai })
            });
        }

        private int? GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
                return userId;
            return null;
        }

        // ④ POST /api/orders/apply-voucher — Kiểm tra và tính trước mã giảm giá
        [HttpPost("apply-voucher")]
        public async Task<IActionResult> ApplyVoucher([FromBody] ApplyVoucherRequest request)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized(new { message = "Token không hợp lệ." });

            if (string.IsNullOrEmpty(request.MaVoucher))
                return BadRequest(new { message = "Vui lòng nhập mã giảm giá." });

            var user = await _context.NguoiDungs.FindAsync(userId.Value);
            if (user == null) return NotFound(new { message = "Người dùng không tồn tại." });

            // Check giới hạn dùng 5 mã/ngày
            var usagesToday = await _context.HoaDons
                .CountAsync(h => h.MaNguoiDung == userId.Value && h.MaVoucher != null && h.NgayTao.Value.Date == DateTime.Now.Date);
            
            if (usagesToday >= 5)
                return BadRequest(new { message = "Bạn đã sử dụng tối đa 5 mã giảm giá trong hôm nay." });

            var voucher = await _context.VoucherHangs.FirstOrDefaultAsync(v => v.MaCode == request.MaVoucher);
            if (voucher == null) 
                return BadRequest(new { message = "Mã giảm giá không hợp lệ hoặc không tồn tại." });

            // Validate Voucher có đúng với Hạng của User không
            var hangCuaVoucher = await _context.HangThanhViens.FindAsync(voucher.MaHang);
            if (hangCuaVoucher == null || hangCuaVoucher.TenHang != user.HangThanhVien)
                return BadRequest(new { message = $"Mã giảm giá này đặc quyền dành riêng cho hạng {hangCuaVoucher?.TenHang}." });

            return Ok(new { 
                message = "Áp dụng mã thành công!", 
                phanTramGiam = hangCuaVoucher.PhanTramUuDai 
            });
        }
    }

    public class ApplyVoucherRequest
    {
        public string MaVoucher { get; set; } = string.Empty;
    }

    public class CheckoutRequest
    {
        public string? PhuongThucThanhToan { get; set; }
        public string? MaVoucher { get; set; }
    }
}
