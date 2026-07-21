using API.Common;
using System.ComponentModel.DataAnnotations;

namespace API.ExceptionHandling;

public interface IExceptionHandler
{
    int Priority { get; }
    bool CanHandle(Exception ex);
    Task<(ApiResult Result, int StatusCode)> HandleAsync(HttpContext context, Exception ex);
}

public class DefaultExceptionHandler : IExceptionHandler
{
    public int Priority => int.MaxValue; // lowest precedence
    public bool CanHandle(Exception ex) => true;
    public Task<(ApiResult Result, int StatusCode)> HandleAsync(HttpContext context, Exception ex)
    {
        var apiResult = new ApiResult("99999", ex.Message, "Internal server error");
        return Task.FromResult((apiResult, StatusCodes.Status500InternalServerError));
    }
}

public class ValidationExceptionHandler : IExceptionHandler
{
    public int Priority => 1;
    public bool CanHandle(Exception ex) => ex is ValidationException;
    public Task<(ApiResult Result, int StatusCode)> HandleAsync(HttpContext context, Exception ex)
    {
        var ve = (ValidationException)ex;
        var apiResult = new ApiResult(ResultCode.INVALID_INPUT, ex.Message, ResultCode.GetBadRequestMessage(ResultCode.INVALID_INPUT));
        return Task.FromResult((apiResult, StatusCodes.Status400BadRequest));
    }
}