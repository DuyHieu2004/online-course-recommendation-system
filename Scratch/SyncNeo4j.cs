using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Neo4j.Driver;
using online_course_recommendation_system.Data;
using online_course_recommendation_system.Models;
using Microsoft.Extensions.Options;
using online_course_recommendation_system.Configurations;

namespace online_course_recommendation_system.Scratch
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var host = Host.CreateDefaultBuilder(args)
                .ConfigureServices((hostContext, services) =>
                {
                    services.AddDbContext<AppDbContext>(options =>
                        options.UseSqlServer(hostContext.Configuration.GetConnectionString("DefaultConnection")));
                    
                    services.Configure<Neo4jSettings>(hostContext.Configuration.GetSection("Neo4j"));
                    services.AddSingleton<IDriver>(sp =>
                    {
                        var config = sp.GetRequiredService<IOptions<Neo4jSettings>>().Value;
                        return GraphDatabase.Driver(config.Uri, AuthTokens.Basic(config.Username, config.Password), o => o.WithEncryptionLevel(EncryptionLevel.None));
                    });
                })
                .Build();

            using var scope = host.Services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var driver = scope.ServiceProvider.GetRequiredService<IDriver>();
            var neo4jSettings = scope.ServiceProvider.GetRequiredService<IOptions<Neo4jSettings>>().Value;

            Console.WriteLine("Bắt đầu đồng bộ dữ liệu sang Neo4j...");

            try
            {
                var categories = await context.TheLoais.ToListAsync();
                var courses = await context.KhoaHocs.ToListAsync();

                await using var session = driver.AsyncSession(o => o.WithDatabase(neo4jSettings.Database));

                await session.ExecuteWriteAsync(async tx =>
                {
                    Console.WriteLine($"Đang đồng bộ {categories.Count} thể loại...");
                    foreach (var cat in categories)
                    {
                        await tx.RunAsync("MERGE (t:TheLoai {id: $id}) SET t.ten = $ten", 
                            new { id = cat.MaTheLoai, ten = cat.Ten });
                    }

                    Console.WriteLine($"Đang đồng bộ {courses.Count} khóa học...");
                    foreach (var kh in courses)
                    {
                        await tx.RunAsync("MERGE (kh:KhoaHoc {id: $id}) SET kh.tieuDe = $tieuDe, kh.urlAnh = $urlAnh, kh.giaGoc = $giaGoc", 
                            new { id = kh.MaKhoaHoc, tieuDe = kh.TieuDe, urlAnh = kh.AnhUrl, giaGoc = (double)(kh.GiaGoc ?? 0) });

                        if (kh.MaTheLoai.HasValue)
                        {
                            await tx.RunAsync("MATCH (kh:KhoaHoc {id: $khId}), (t:TheLoai {id: $tId}) MERGE (kh)-[:THUOC_THE_LOAI]->(t)", 
                                new { khId = kh.MaKhoaHoc, tId = kh.MaTheLoai.Value });
                        }
                    }
                });

                Console.WriteLine("Đồng bộ hoàn tất thành công!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Lỗi: {ex.Message}");
            }
        }
    }
}
