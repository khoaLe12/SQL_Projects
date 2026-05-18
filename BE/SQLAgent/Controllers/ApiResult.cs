namespace SQLAgent.Controllers;

public class ApiResult
{
    public string StatusCode { get; private set; }
    public object Data { get; private set; }
    public string Message { get; private set; }

    public ApiResult(string statusCode, object data, string message)
    {
        StatusCode = statusCode;
        Data = data;
        Message = message;
    }
}
