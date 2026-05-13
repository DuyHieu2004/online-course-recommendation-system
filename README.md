# online-course-recommendation-system
# 1. online-course-recommendation-system
 1.1. Đồng bộ ip của mobile và .net core (điện thoại cắm usb qua laptop)
```bash
adb reverse tcp:5128 tcp:5128
# Kết quả mong đợi: 5128
```
 1.2. Thay đổi Properties/launchSettings.jon và mobile:
```bash
http://127.0.0.1:5128
```
 1.3. Database first
``` bash
dotnet ef dbcontext scaffold "Server=localhost;Database=ELearning_DB;Trusted_Connection=True;TrustServerCertificate=True;" Microsoft.EntityFrameworkCore.SqlServer -o Models --context-dir Data -c AppDbContext --force
```

# 2. Hướng dẫn thiết lập cấu hình môi trường (.json)
Vì lý do bảo mật, file cấu hình chứa chuỗi kết nối và mật khẩu đã được loại khỏi Git. Khi clone code về, bạn cần tạo lại 2 file này từ file mẫu:
1. Đổi tên (hoặc copy) `appsettings.example.json` thành `appsettings.json`.
2. Đổi tên (hoặc copy) `appsettings.Development.example.json` thành `appsettings.Development.json` (dành cho chạy localhost).
3. Mở các file vừa tạo và điền thông tin thật của `Server` cho SQL Server, `Password` cho database Neo4j, và thiết lập `Key` cho đoạn xài JWT Token (chuỗi ngẫu nhiên bí mật).
