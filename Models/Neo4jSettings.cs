namespace online_course_recommendation_system.Configurations
{
    public class Neo4jSettings
    {
        public string Uri { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Database { get; set; } = "neo4j";
    }
}