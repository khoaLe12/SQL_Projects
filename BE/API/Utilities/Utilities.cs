using Microsoft.AspNetCore.Cryptography.KeyDerivation;
using System.Security.Cryptography;
using System.Text;

namespace API.Common;

public static class Utilities
{
    private static byte[] salt = new byte[0];

    public static void Initialize(IConfiguration config)
    {
        salt = Encoding.UTF8.GetBytes((string?)config.GetValue(typeof(string), "Salt") ?? throw new ArgumentNullException("Salt not found"));
    }

    public static void Log(Exception ex)
    {
        string filename = DateTime.Now.ToString("yyyy-MM-dd") + ".txt";
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

    public static void AgentLog(string message)
    {
        string filename = DateTime.Now.ToString("yyyy-MM-dd") + ".txt";
        string contentRoot = Environment.CurrentDirectory;
        string logFile = Path.Combine(contentRoot, "AgentLog\\", filename);
        if (!File.Exists(logFile))
        {
            using (Stream s = File.Create(logFile))
            {
                using (StreamWriter w = new StreamWriter(s, Encoding.UTF8))
                {
                    w.Write(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " - " + message);
                }
            }
        }
        else
        {
            File.AppendAllLines(logFile, new List<string> {
                "\n",
                DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " - " + message
            });
        }
    }

    public static string HashPassword(string password, int iterations = 100000)
    {
        // derive a 128-bit subkey (use HMACSHA256 with 100,000 iterations)
        byte[] array = KeyDerivation.Pbkdf2(
                password: password,
                salt: salt,
                prf: KeyDerivationPrf.HMACSHA256,
                iterations,
                128 / 8
        );

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < array.Length; i++)
        {
            byte b = array[i];
            sb.Append(b.ToString("x2").ToUpper() + "-");
        }
        sb = sb.Remove(sb.Length - 1, 1);

        return sb.ToString();
    }
}
