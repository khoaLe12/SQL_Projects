using API.DapperImplementation.Base;
using API.Models.SysEntities;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace API.Common;

public interface IJwtTokenProvider
{
    string CreateSecurityToken(sysUserInfo user, List<sysUserPrivilege> privileges);
    TransactionInformation? VerifySecurityToken(string token);
}

public class JwtTokenProvider : IJwtTokenProvider
{
    private readonly IKeyManager _keyManager;
    private readonly IConfiguration _configuration;

    public JwtTokenProvider(IKeyManager keyManager, IConfiguration configuration)
    {
        _keyManager = keyManager;
        _configuration = configuration;
    }

    public string CreateSecurityToken (sysUserInfo user, List<sysUserPrivilege> privileges)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username)
        };

        if (privileges.Count() > 0)
        {
            foreach(var privilege in privileges)
            {
                if (privilege is not null && !string.IsNullOrEmpty(privilege.Action_code) && !string.IsNullOrEmpty(privilege.Scope))
                {
                    claims.Add(new Claim("scope", $"{privilege.Scope}:{privilege.Action_code}"));
                }
            }
        }

        var key = new RsaSecurityKey(_keyManager.JWTKey);
        var creds = new SigningCredentials(key, SecurityAlgorithms.RsaSha256);

        var jwtToken = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(jwtToken);
    }
    public TransactionInformation? VerifySecurityToken(string token)
    {
        if (string.IsNullOrEmpty(token)) return null;

        var validationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = _configuration["Jwt:Issuer"],
            ValidateAudience = true,
            ValidAudience = _configuration["Jwt:Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new RsaSecurityKey(_keyManager.JWTKey),
            ValidateLifetime = true,
        };

        try
        {
            JwtSecurityTokenHandler handler = new JwtSecurityTokenHandler();
            handler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
            JwtSecurityToken jwt = (JwtSecurityToken)validatedToken;

            var transaction = new TransactionInformation();
            transaction.Claims = jwt.Claims.ToList();
            transaction.User_id = jwt.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value ?? "";
            transaction.User_name = jwt.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Name)?.Value ?? "";
            transaction.Roles = jwt.Claims.Where(c => c.Type == "scope").Select(c => c.Value).ToList();
            transaction.JWTToken = token;
            transaction.ExpireAt = jwt.ValidTo;

            List<sysUserPrivilege> sysUserPrivileges = new List<sysUserPrivilege>();
            foreach (var role in transaction.Roles)
            {
                string[] parts = role.Split(":");
                if (parts.Length == 2)
                {
                    sysUserPrivilege sysUserPrivilege = new sysUserPrivilege("", transaction.User_id, parts[0], parts[1]);
                    sysUserPrivileges.Add(sysUserPrivilege);
                }
            }
            transaction.sysUserPrivileges = sysUserPrivileges;

            return transaction;
        }
        catch (Exception ex)
        {
            Utilities.Log(ex);
            return null;
        }
    }
}
