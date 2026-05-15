using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace online_course_recommendation_system.Service
{
    public class CloudinaryService : ICloudinaryService
    {
        private readonly Cloudinary _cloudinary;

        public CloudinaryService(IConfiguration config)
        {
            var acc = new Account(
                config["CloudinarySettings:CloudName"],
                config["CloudinarySettings:ApiKey"],
                config["CloudinarySettings:ApiSecret"]
            );
            _cloudinary = new Cloudinary(acc);
        }

        public async Task<string?> UploadFileAsync(IFormFile file, string folder)
        {
            try
            {
                if (file == null || file.Length == 0) return null;

                var extension = Path.GetExtension(file.FileName).ToLower();
                Console.WriteLine($"--- CLOUDINARY UPLOAD START: {file.FileName} ({file.Length} bytes) ---");

                // Handle images vs other files (PDFs, Videos)
                if (extension == ".pdf" || extension == ".doc" || extension == ".docx" || extension == ".zip" || extension == ".rar")
                {
                    var uploadParams = new RawUploadParams()
                    {
                        File = new FileDescription(file.FileName, file.OpenReadStream()),
                        Folder = folder
                    };

                    var uploadResult = await _cloudinary.UploadAsync(uploadParams);
                    if (uploadResult.Error != null)
                    {
                        Console.WriteLine($"CLOUDINARY RAW ERROR: {uploadResult.Error.Message}");
                    }
                    return uploadResult?.SecureUrl?.ToString();
                }
                else if (extension == ".mp4" || extension == ".mov" || extension == ".avi" || extension == ".webm" || extension == ".mkv")
                {
                    var uploadParams = new VideoUploadParams()
                    {
                        File = new FileDescription(file.FileName, file.OpenReadStream()),
                        Folder = folder
                    };

                    var uploadResult = await _cloudinary.UploadAsync(uploadParams);
                    if (uploadResult.Error != null)
                    {
                        Console.WriteLine($"CLOUDINARY VIDEO ERROR: {uploadResult.Error.Message}");
                    }
                    return uploadResult?.SecureUrl?.ToString();
                }
                else
                {
                    var uploadParams = new ImageUploadParams()
                    {
                        File = new FileDescription(file.FileName, file.OpenReadStream()),
                        Folder = folder
                    };

                    var uploadResult = await _cloudinary.UploadAsync(uploadParams);
                    if (uploadResult.Error != null)
                    {
                        Console.WriteLine($"CLOUDINARY IMAGE ERROR: {uploadResult.Error.Message}");
                    }
                    return uploadResult?.SecureUrl?.ToString();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"CLOUDINARY EXCEPTION: {ex.Message}");
                return null;
            }
        }
    }
}
