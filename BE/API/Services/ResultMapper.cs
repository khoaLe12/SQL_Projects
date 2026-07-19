using Newtonsoft.Json.Linq;
using API.Common;

namespace API.Services;

public class ResultMapper : IResultMapper
{
    private const string SuccessCode = "00000";
    private const string DefaultErrorCode = "99999";

    public ApiResult MapQueryResult(IEnumerable<dynamic> result, string? customMessage = null)
    {
        return new ApiResult(
            ResultCode.SUCCESS,
            result ?? new List<dynamic>(),
            customMessage ?? "Query executed successfully"
        );
    }

    public ApiResult MapBatchInsertResult(JArray insertData, int returnCode)
    {
        string resultCode = "00000";
        string message = "Batch insert executed successfully";
        if (returnCode != 0)
        {
            resultCode = ResultCode.GetInsertResultCode(returnCode);
            message = ResultCode.GetInsertMessage(resultCode);
        }
        return new ApiResult(resultCode, insertData, message);
    }

    public ApiResult MapInsertResult(JObject insertData, dynamic? generatedKeys = null, int returnCode = 0)
    {
        string resultCode = "00000";
        string message = "Insert executed successfully";
        if (returnCode != 0)
        {
            resultCode = ResultCode.GetInsertResultCode(returnCode);
            message = ResultCode.GetInsertMessage(resultCode);
        }
        if (generatedKeys is not null)
        {
            var keyMaps = (IDictionary<string, object>)generatedKeys;
            foreach (var key in keyMaps)
            {
                insertData[key.Key] = JToken.FromObject(key.Value ?? "");
            }
        }
        return new ApiResult(resultCode, insertData, message);
    }

    public ApiResult MapUpdateResult(int returnCode, JObject? updatedData = null)
    {
        string resultCode = "00000";
        string message = "Update executed successfully";
        if (returnCode != 0)
        {
            resultCode = ResultCode.GetUpdateResultCode(returnCode);
            message = ResultCode.GetUpdateMessage(resultCode);
        }
        return new ApiResult(resultCode, updatedData ?? new JObject(), message);
    }

    public ApiResult MapDeleteResult(int returnCode)
    {
        string resultCode = "00000";
        string message = "Delete executed successfully";
        if (returnCode != 0)
        {
            resultCode = ResultCode.GetDeleteResultCode(returnCode);
            message = ResultCode.GetDeleteMessage(resultCode);
        }
        return new ApiResult(resultCode, "", message);
    }
}
