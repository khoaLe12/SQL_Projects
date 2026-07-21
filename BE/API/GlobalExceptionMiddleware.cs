using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using API.Common;
using System.Net;
using API.ExceptionHandling;

namespace API;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IEnumerable<IExceptionHandler> _handlers;

    public GlobalExceptionMiddleware(RequestDelegate next, IEnumerable<IExceptionHandler> handlers)
    {
        _next = next;
        _handlers = handlers.OrderBy(h => h.Priority).ToArray() ?? Array.Empty<IExceptionHandler>();
    }

    public async Task InvokeAsync(HttpContext httpContext)
    {
        try
        {
            await _next(httpContext);
        }
        catch (Exception ex)
        {
            Common.Utilities.Log(ex);
            await HandleExceptionAsync(httpContext, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception ex)
    {
        var handler = _handlers.FirstOrDefault(h => h.CanHandle(ex));
        if (handler == null)
        {
            var fallback = new ApiResult("99999", ex.Message, "Internal server error");
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsync(fallback.ToString());
            return;
        }

        var (apiResult, statusCode) = await handler.HandleAsync(context, ex);
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = statusCode;
        await context.Response.WriteAsync(apiResult.ToString());
        //await context.Response.WriteAsJsonAsync(apiResult);
    }
}

