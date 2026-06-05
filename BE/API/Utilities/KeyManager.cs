using System.Security.Cryptography;

namespace API.Utilities;

public interface IKeyManager
{
    public RSA JWTKey { get; }
    public RSA Key { get; }
}

public class KeyManager : IKeyManager
{
    public RSA JWTKey { get; }
    public RSA Key { get; }

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
    }
}
