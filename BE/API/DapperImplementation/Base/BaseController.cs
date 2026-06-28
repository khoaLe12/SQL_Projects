using API.Common;
using API.Models.SysEntities;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.DataProtection.KeyManagement;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Primitives;
using Newtonsoft.Json;
using System.Net;
using System.Security.Claims;
using IKeyManager = API.Common.IKeyManager;

namespace API.DapperImplementation.Base;

public class TransactionInformation
{
    public bool IsValidJWT { get; set; } = false;
    public bool IsValidKey { get; set; } = false;
    public HttpRequest? Request { get; set; } = null;
    public string TransactionId { get; set; } = string.Empty;
    public string User_name { get; set; } = string.Empty;
    public string User_id { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public DateTime ExpireAt { get; set; }
    public string JWTToken { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = new List<string>();
    public List<Claim> Claims { get; set; } = new List<Claim>();
    public List<sysUserPrivilege> sysUserPrivileges { get; set; } = new List<sysUserPrivilege>();

    public override string ToString()
    {
        return JsonConvert.SerializeObject(new
        {
            IsValidJWT = IsValidJWT,
            IsValidKey = IsValidKey,
            TransactionId = TransactionId,
            User_name = User_name,
            User_id = User_id,
            ApiKey = ApiKey,
            JWTToken = JWTToken,
            ExpireAt = ExpireAt.ToString("yyyy-MM-dd HH:mm:ss"),
            Roles = Roles,
            SysUserPrivileges = sysUserPrivileges.Select(p => new
            {
                Module = p.Scope,
                Action_code = p.Action_code
            })
        });
    }

    public object ToObject()
    {
        return new
        {
            IsValidJWT = IsValidJWT,
            IsValidKey = IsValidKey,
            TransactionId = TransactionId,
            User_name = User_name,
            User_id = User_id,
            ApiKey = ApiKey,
            JWTToken = JWTToken,
            ExpireAt = ExpireAt.ToString("yyyy-MM-dd HH:mm:ss"),
            Roles = Roles,
            SysUserPrivileges = sysUserPrivileges.Select(p => new
            {
                Module = p.Scope,
                Action_code = p.Action_code
            })
        };
    }
}

public class BaseController : ControllerBase, IActionFilter
{
    private readonly IJwtTokenProvider _jwtTokenProvider;
    private readonly IKeyManager _keyManager;

    protected TransactionInformation Transaction { get; set; } = new TransactionInformation();

    public BaseController(IJwtTokenProvider jwtTokenProvider, IKeyManager keyManager)
    {
        _jwtTokenProvider = jwtTokenProvider;
        _keyManager = keyManager;
    }

    [ApiExplorerSettings(IgnoreApi = true)]
    public void OnActionExecuting(ActionExecutingContext context)
    {
        IHeaderDictionary headers = Request.Headers;
        StringValues apiKeys = headers["Api-Key"];
        StringValues jwtTokens = headers["Authorization"];

        // Manually verify api key and security JWT token
        string? jwtToken = jwtTokens.FirstOrDefault();
        TransactionInformation? transaction = _jwtTokenProvider.VerifySecurityToken(jwtToken?.Replace("Bearer ", "") ?? "");
        if (transaction is null)
        {
            transaction = new TransactionInformation();
            transaction.IsValidJWT = false;
        }
        else
        {
            transaction.IsValidJWT = true;
        }

        transaction.ApiKey = apiKeys.FirstOrDefault() ?? "";
        if (_keyManager.ApiKey == transaction.ApiKey)
        {
            transaction.IsValidKey = true;
        }

        transaction.Request = Request;
        Transaction = transaction;
    }

    [ApiExplorerSettings(IgnoreApi = true)]
    public void OnActionExecuted(ActionExecutedContext context)
    {
    }
}
