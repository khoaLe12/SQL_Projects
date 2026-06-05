using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Primitives;
using System.Net;
using System.Security.Claims;

namespace API.DapperImplementation.Base;

public class TransactionInformation
{
    public HttpRequest? Request { get; set; } = null;
    public string TransactionId { get; set; } = string.Empty;
    public string User_name { get; set; } = string.Empty;
    public string User_id { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    public DateTime ExpireAt { get; set; }
    public string JWTToken { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = new List<string>();
    public List<Claim> Claims { get; set; } = new List<Claim>();
}

public class BaseController : ControllerBase
{
    protected TransactionInformation Transaction { get; set; }

    public BaseController()
    {
        TransactionInformation transaction = new TransactionInformation();
        transaction.Request = Request;

        IHeaderDictionary headers = Request.Headers;
        StringValues token = headers["token"];
        if (token != StringValues.Empty)
        {
            transaction.Token = token[0] ?? "";
        }

        List<Claim> claims = User.Claims.ToList();
        transaction.Claims = claims;

        transaction.User_id = claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value ?? "";
        transaction.User_name = claims.FirstOrDefault(c => c.Type == ClaimTypes.Name)?.Value ?? "";
        transaction.Roles = claims.Where(c => c.Type == "scope").Select(c => c.Value).ToList();

        transaction.JWTToken = headers["Authorization"].ToString().Replace("Bearer ", "");

        Transaction = transaction;
    }
}
