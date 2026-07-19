using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace API.Common;

public class ApiResult
{
    public string StatusCode { get; set; }
    public object Data { get; set; }
    public string Message { get; set; }

    public ApiResult()
    {
        StatusCode = string.Empty;
        Data = new object();
        Message = string.Empty;
    }

    public ApiResult(string statusCode, object data, string message)
    {
        StatusCode = statusCode;
        Data = data;
        Message = message;
    }

    public override string ToString()
    {
        return $"{{\"StatusCode\":\"{StatusCode}\", \"Data\":\"{Data.ToString()}\", \"Message\":\"{Message}\"}}";
    }
}
