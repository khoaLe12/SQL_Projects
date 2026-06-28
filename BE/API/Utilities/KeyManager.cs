using System.Security.Cryptography;
using System.Text;

namespace API.Common;

public interface IKeyManager
{
    public RSA JWTKey { get; }
    public RSA Key { get; }
    public string ApiKey { get; }
    public byte[] Salt { get; }
}

public class KeyManager : IKeyManager
{
    public RSA JWTKey { get; }
    public RSA Key { get; }
    public string ApiKey { get; }
    public byte[] Salt { get; }

    public KeyManager()
    {
        JWTKey = RSA.Create();
        Key = RSA.Create();

        if (File.Exists("jwt.key"))
        {
            var jwtKeyData = File.ReadAllBytes("jwt.key");
            JWTKey.ImportRSAPrivateKey(jwtKeyData, out _);
        }
        else
        {
            File.WriteAllBytes("jwt.key", JWTKey.ExportRSAPrivateKey());
        }

        if (File.Exists("key"))
        {
            var keyData = File.ReadAllBytes("key");
            Key.ImportRSAPrivateKey(keyData, out _);
        }
        else
        {
            File.WriteAllBytes("key", Key.ExportRSAPrivateKey());
        }

        if (File.Exists("apiKey"))
        {
            // Base64 Decode
            var base64Key = File.ReadAllText("apiKey");
            var keyBytes = Convert.FromBase64String(base64Key);
            ApiKey = Encoding.UTF8.GetString(keyBytes);
        }
        else
        {
            int keysLength = 50;
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

            StringBuilder stringBuilder = new StringBuilder();
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
            {
                byte[] buffer = new byte[4];
                for (int i = 1; i <= keysLength; i++)
                {
                    rng.GetBytes(buffer);
                    uint num =  BitConverter.ToUInt32(buffer, 0);
                    stringBuilder.Append(chars[(int)(num % (uint)chars.Length)]);
                }
            }

            ApiKey = stringBuilder.ToString();
            var keyBytes = Encoding.UTF8.GetBytes(ApiKey);
            var base64Key = Convert.ToBase64String(keyBytes);
            File.WriteAllText("apiKey", base64Key);
        }

        if (File.Exists("salt"))
        {
            Salt = File.ReadAllBytes("salt");
        }
        else
        {
            Salt = GenerateSalt(16);
            File.WriteAllBytes("salt", Salt);
        }
    }

    private byte[] GenerateSalt(int size)
    {
        byte[] salt = new byte[size];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(salt);
        }
        return salt;
    }
}
