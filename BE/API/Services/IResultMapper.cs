using Newtonsoft.Json.Linq;
using API.Common;

namespace API.Services;

public interface IResultMapper
{
    ApiResult MapQueryResult(IEnumerable<dynamic> result, string? customMessage = null);

    ApiResult MapBatchInsertResult(JArray insertData, int returnCode);
    ApiResult MapInsertResult(JObject insertData, dynamic? generatedKeys = null, int returnCode = 0);

    ApiResult MapUpdateResult(int returnCode, JObject? updatedData = null);

    ApiResult MapDeleteResult(int returnCode);
}
