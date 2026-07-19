using Dapper;
using Newtonsoft.Json.Linq;

namespace API.Services;

/// <summary>
/// Responsible for converting JSON objects to database parameters.
/// Single Responsibility: Handle parameter extraction and conversion only.
/// </summary>
public interface IParameterBuilder
{
    /// <summary>
    /// Builds DynamicParameters from a JObject.
    /// </summary>
    DynamicParameters Build(JObject jsonObject);

    /// <summary>
    /// Builds DynamicParameters from a JArray of objects.
    /// </summary>
    List<DynamicParameters> BuildArray(JArray jsonArray);

    /// <summary>
    /// Adds a return parameter to track stored procedure execution status.
    /// </summary>
    void AddReturnParameter(DynamicParameters parameters, string parameterName = "@pRet");
}
