using API.Common;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;

namespace API.Services;

public interface IResponseBuilder
{
    IActionResult ToJsonResult(ApiResult apiResult);

    IActionResult BuildFailureResponse(string statusCode, string message);

    IActionResult HandleException(Exception ex);
}