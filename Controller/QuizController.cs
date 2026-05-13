using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;

namespace online_course_recommendation_system.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class QuizController : ControllerBase
    {
        private readonly AppDbContext _context;

        public QuizController(AppDbContext context)
        {
            _context = context;
        }

        private int? GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
                return userId;
            return null;
        }

        // GET /api/Quiz/chapter/{chapterId} -> Lấy danh sách bài test của chương
        [HttpGet("chapter/{chapterId}")]
        public async Task<IActionResult> GetQuizzesByChapter(int chapterId)
        {
            var quizzes = await _context.BaiKiemTras
                .Where(q => q.MaChuong == chapterId)
                .Select(q => new
                {
                    q.MaBaiKiemTra,
                    q.TieuDe,
                    q.MoTa,
                    q.ThoiGianLamBai,
                    SoCauHoi = q.CauHois.Count
                })
                .ToListAsync();

            return Ok(quizzes);
        }

        // GET /api/Quiz/{id} -> Lấy chi tiết bài test và câu hỏi (không gửi đáp án đúng)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetQuizDetails(int id)
        {
            var quiz = await _context.BaiKiemTras
                .Where(q => q.MaBaiKiemTra == id)
                .Select(q => new
                {
                    q.MaBaiKiemTra,
                    q.TieuDe,
                    q.MoTa,
                    q.ThoiGianLamBai,
                    CauHois = q.CauHois.Select(c => new
                    {
                        c.MaCauHoi,
                        c.NoiDung,
                        c.Diem,
                        LuaChons = c.LuaChons.Select(l => new
                        {
                            l.MaLuaChon,
                            l.NoiDung
                        })
                    })
                })
                .FirstOrDefaultAsync();

            if (quiz == null) return NotFound(new { message = "Không tìm thấy bài test" });
            return Ok(quiz);
        }

        // POST /api/Quiz/{id}/submit -> Chấm điểm bài test
        [HttpPost("{id}/submit")]
        [Authorize]
        public async Task<IActionResult> SubmitQuiz(int id, [FromBody] List<QuizAnswerRequest> answers)
        {
            var userId = GetUserIdFromToken();
            if (userId == null) return Unauthorized();

            var quiz = await _context.BaiKiemTras
                .Include(q => q.CauHois)
                .ThenInclude(c => c.LuaChons)
                .FirstOrDefaultAsync(q => q.MaBaiKiemTra == id);

            if (quiz == null) return NotFound();

            double totalScore = 0;
            double maxScore = 0;

            foreach (var cauHoi in quiz.CauHois)
            {
                maxScore += cauHoi.Diem;
                var userAnswer = answers.FirstOrDefault(a => a.MaCauHoi == cauHoi.MaCauHoi);
                if (userAnswer != null)
                {
                    var isCorrect = cauHoi.LuaChons.Any(l => l.MaLuaChon == userAnswer.MaLuaChon && l.LaDapAnDung);
                    if (isCorrect)
                    {
                        totalScore += cauHoi.Diem;
                    }
                }
            }

            // Lưu kết quả
            var result = new KetQuaKiemTra
            {
                MaNguoiDung = userId.Value,
                MaBaiKiemTra = id,
                DiemSo = totalScore,
                NgayNopBai = DateTime.Now
            };
            _context.KetQuaKiemTras.Add(result);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                TotalScore = totalScore,
                MaxScore = maxScore,
                Percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0
            });
        }
    }

    public class QuizAnswerRequest
    {
        public int MaCauHoi { get; set; }
        public int MaLuaChon { get; set; }
    }
}
