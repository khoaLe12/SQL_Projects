using Dapper;
using Newtonsoft.Json.Linq;

namespace API.Services;

public class ParameterBuilder : IParameterBuilder
{
    /// <summary>
    /// Converts JObject properties to DynamicParameters for Dapper.
    /// </summary>
    public DynamicParameters Build(JObject jsonObject)
    {
        if (jsonObject == null)
        {
            return new DynamicParameters();
        }

        var parameters = new DynamicParameters();

        foreach (var property in jsonObject.Properties())
        {
            var value = ConvertValue(property);
            parameters.Add(property.Name, value);
        }

        return parameters;
    }

    /// <summary>
    /// Converts an array of JObjects to a list of DynamicParameters.
    /// </summary>
    public List<DynamicParameters> BuildArray(JArray jsonArray)
    {
        if (jsonArray == null || jsonArray.Count == 0)
        {
            return new List<DynamicParameters>();
        }

        var parametersList = new List<DynamicParameters>();

        foreach (var item in jsonArray)
        {
            if (item is JObject jObject)
            {
                parametersList.Add(Build(jObject));
            }
        }

        return parametersList;
    }

    /// <summary>
    /// Adds a return parameter to track stored procedure execution status.
    /// </summary>
    public void AddReturnParameter(DynamicParameters parameters, string parameterName = "@pRet")
    {
        if (parameters == null)
        {
            throw new ArgumentNullException(nameof(parameters));
        }

        parameters.Add(parameterName, dbType: System.Data.DbType.Int32, direction: System.Data.ParameterDirection.Output);
    }

    /// <summary>
    /// Converts JToken values to appropriate C# types.
    /// </summary>
    private static object? ConvertValue(JProperty property)
    {
        return property.Type switch
        {
            JTokenType.Date => property.Value.Value<DateTime>(),
            JTokenType.Integer => property.Value.Value<int>(),
            JTokenType.Float => property.Value.Value<decimal>(),
            JTokenType.Boolean => property.Value.Value<bool>(),
            JTokenType.Null => null,
            _ => property.Value.ToString()
        };
    }
}
