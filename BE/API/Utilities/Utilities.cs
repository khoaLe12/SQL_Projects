using System.Text;

namespace API.Utilities;

public static class Utilities
{
    public static void Log(Exception ex)
    {
        string filename = DateTime.Now.ToString("dd-MM-yyyy") + ".txt";
        string contentRoot = Environment.CurrentDirectory;
        string logFile = Path.Combine(contentRoot, "Logs\\", filename);
        if (!File.Exists(logFile))
        {
            using (Stream s = File.Create(logFile))
            {
                using (StreamWriter w = new StreamWriter(s, Encoding.UTF8))
                {
                    w.Write(ex.ToString());
                }
            }
        }
        else
        {
            File.AppendAllLines(logFile, new List<string> { 
                "\n===============================================================================\n", 
                ex.ToString() 
            });
        }
    }
}
