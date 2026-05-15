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
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));



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
        policy.WithOrigins("http://localhost:4200")
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
app.UseHttpsRedirection();
app.UseCors("AllowAngular");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();