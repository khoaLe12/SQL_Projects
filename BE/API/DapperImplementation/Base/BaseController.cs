using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Primitives;
using System.Net;

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
}

public class BaseController : ControllerBase
{
    protected bool IsValidToken { get; set; } = false;
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
            if (!string.IsNullOrEmpty(transaction.Token))
            {
                IsValidToken = true;
            }
        }
        Transaction = transaction;
    }
}
