namespace SQLAgent.Services;

public static class Utilities
{
    public static void Log(Exception ex)
    {
        string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
        string logFile = Path.Combine(baseDirectory, "\\Log\\log.txt");
        File.WriteAllText(logFile, ex.ToString());
    }
}
