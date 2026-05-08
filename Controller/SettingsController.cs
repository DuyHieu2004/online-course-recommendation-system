using Microsoft.AspNetCore.Mvc;
using online_course_recommendation_system.Models;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;

namespace online_course_recommendation_system.Controller
{
    [ApiController]
    [Route("api/[controller]")]
    public class SettingsController : ControllerBase
    {
        private readonly string _settingsPath = Path.Combine(Directory.GetCurrentDirectory(), "Data", "systemsettings.json");

        [HttpGet]
        public async Task<IActionResult> GetSettings()
        {
            if (!System.IO.File.Exists(_settingsPath))
            {
                return Ok(new GlobalSettings());
            }

            var json = await System.IO.File.ReadAllTextAsync(_settingsPath);
            var settings = JsonSerializer.Deserialize<GlobalSettings>(json);
            return Ok(settings);
        }

        [HttpPost]
        public async Task<IActionResult> UpdateSettings([FromBody] GlobalSettings settings)
        {
            var json = JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true });
            
            // Ensure directory exists
            var dir = Path.GetDirectoryName(_settingsPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir!);

            await System.IO.File.WriteAllTextAsync(_settingsPath, json);
            return Ok(new { message = "Settings updated successfully" });
        }
    }
}
