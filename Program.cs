using Neo4j.Driver;

using online_course_recommendation_system.Configurations;
using Microsoft.EntityFrameworkCore;
using online_course_recommendation_system.Data;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using online_course_recommendation_system.Service;
using online_course_recommendation_system.Models;

var builder = WebApplication.CreateBuilder(args);

// Đăng ký EF Core kết nối SQL Server
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"),
    sqlServerOptionsAction: sqlOptions =>
    {
        // Cho phép backend thử kết nối lại tối đa 5 lần, cách nhau 30s để đợi SQL Server boot xong
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null);
    }));



// bind config
builder.Services.Configure<Neo4jSettings>(
    builder.Configuration.GetSection("Neo4j")
);
builder.Services.Configure<SmtpSettings>(
    builder.Configuration.GetSection("Smtp")
);

// Register Email Service
builder.Services.AddScoped<IEmailService, EmailService>();

// đăng ký IDriver singleton
builder.Services.AddSingleton<IDriver>(sp =>
{
    var config = builder.Configuration.GetSection("Neo4j").Get<Neo4jSettings>()
                 ?? throw new Exception("Neo4j configuration is missing.");

    return GraphDatabase.Driver(
        config.Uri,
        AuthTokens.Basic(config.Username, config.Password)
    );
});

// CORS cho Frontend Angular
builder.Services.AddHostedService<DeadlineReminderWorker>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular", policy =>
    {
        policy.WithOrigins("http://20.239.91.134", "http://localhost:4200", "http://khoa-hoc-elearning.me")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Thêm Service Cloudinary
builder.Services.AddScoped<online_course_recommendation_system.Service.ICloudinaryService, online_course_recommendation_system.Service.CloudinaryService>();

// 1. Thêm các Controllers vào hệ thống
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });

// 2. KHÚC NÀY ĐỂ BẬT SWAGGER NÈ
builder.Services.AddEndpointsApiExplorer();

// Thay đổi ở đây: CẤU HÌNH SWAGGER CÓ HỖ TRỢ JWT AUTHENTICATION
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "API Gợi ý Khóa học v1", Version = "v1" });

    // Cấu hình nút Authorize trên Swagger UI
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Chỉ cần dán Token của bạn vào đây (không cần gõ chữ Bearer).",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

builder.Services.AddHttpClient();

// ĐĂNG KÝ JWT AUTHENTICATION VÀO HỆ THỐNG
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });

var app = builder.Build();

// Bật tạm thời tính năng show chi tiết lỗi để dễ debug trên Production
app.UseDeveloperExceptionPage();

// 3. CẤU HÌNH HIỂN THỊ GIAO DIỆN SWAGGER
if (app.Environment.IsDevelopment() || app.Environment.IsEnvironment("Docker"))
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "API Gợi ý Khóa học v1");
    });
}

app.UseStaticFiles();
//app.UseHttpsRedirection();
app.UseCors("AllowAngular");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
// Tự động chạy Migration để tạo Database và các Bảng khi ứng dụng khởi động
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<online_course_recommendation_system.Data.AppDbContext>();
        if (context.Database.GetPendingMigrations().Any())
        {
            context.Database.Migrate();
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Lỗi khi chạy Migration lúc khởi động: {ex.Message}");
    }
}

app.Run();