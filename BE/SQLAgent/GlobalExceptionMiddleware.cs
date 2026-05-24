using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using SQLAgent.Controllers;
using SQLAgent.Services;
using System.Net;

namespace SQLAgent;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;

    public GlobalExceptionMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext httpContext)
    {
        try
        {
            await _next(httpContext);
        }
        catch (Exception ex)
        {
            Utilities.Log(ex);
            await HandleExceptionAsync(httpContext, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception ex)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.OK;
        ApiResult apiResult = new ApiResult("99999", "", "Failed");
        await context.Response.WriteAsync(apiResult.ToString());
        //await context.Response.WriteAsJsonAsync(apiResult);
    }
}
