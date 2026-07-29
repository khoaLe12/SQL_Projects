using API.Common;
using API.DapperImplementation.Base;
using API.DapperImplementation.Base.Repository;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Text.Json;

namespace API.Services;

public class ResponseBuilder : IResponseBuilder
{
    public ResponseBuilder() { }

    public IActionResult ToJsonResult(ApiResult apiResult)
    {
        var result = new JsonResult(apiResult);
        result.StatusCode = ResultCode.GetHttpStatusCode(apiResult.StatusCode);
        return result;
    }

    public IActionResult BuildFailureResponse(string statusCode, string message)
    {
        var result =  new JsonResult(new ApiResult(statusCode, "", message));
        result.StatusCode = ResultCode.GetHttpStatusCode(statusCode);
        return result;
    }

    public IActionResult HandleException(Exception ex)
    {
        Utilities.Log(ex);
        if (ex is EntityRepoException repoException)
        {
            string statusCode = ResultCode.GetRepositoryErrorCode(repoException._errorCode);
            string message = ResultCode.GetRepositoryErrorMessage(statusCode);
            return BuildFailureResponse(statusCode, message);
        }
        else if (ex is BaseADOServiceException serviceException)
        {
            string statusCode = ResultCode.GetServiceErrorCode(serviceException._errorCode);
            string message = ResultCode.GetServiceErrorMessage(statusCode);
            return BuildFailureResponse(statusCode, message);
        }
        else
        {
            return BuildFailureResponse("99999", "An error occurred during operation");
        }
    }
}
