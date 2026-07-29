using API.Models.BaseModel;
using API.Models.SysEntities;
using Dapper;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Globalization;

namespace API.DapperImplementation.Base.Repository;

public interface IBaseRepository { }

public abstract class BaseRepository : IBaseRepository
{
    private readonly AdventureWorks2025Connection _connection;
    protected Dictionary<Type, object> DefaultValues = new Dictionary<Type, object>
    {
        { typeof(string), "" },
        { typeof(int), 0 },
        { typeof(Decimal), 0.0 },
        { typeof(System.Boolean), false },
        { typeof(DateTime), new DateTime(1900, 1, 1) },
        { typeof(TimeOnly), new TimeOnly(0, 0, 0) }
    };

    public BaseRepository(AdventureWorks2025Connection connection)
    {
        _connection = connection;
    }

    protected void SetDeafultValues(Dictionary<Type, object> defaultValues)
    {
        DefaultValues = defaultValues;
    }

    protected void ExecuteNonQuery(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        _connection.ExecuteNonQuery(scName, spName, dynamicParameters);
    }

    protected dynamic ExecuteScalar(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        var result = _connection.ExecuteScalar(scName, spName, dynamicParameters);
        return result;
    }

    protected IEnumerable<dynamic> ExecuteQuery(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        var result = _connection.ExecuteQuery(scName, spName, dynamicParameters);
        return result;
    }

    protected IEnumerable<T> ExecuteQuery<T>(string scName, string spName, ref DynamicParameters dynamicParameters) where T : BaseEntity
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        var result = _connection.ExecuteQuery<T>("dbo", spName, dynamicParameters);
        return result;
    }

    protected dynamic? ExecuteQuerySingle(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        var result = _connection.ExecuteSingleOrDefault(scName, spName, dynamicParameters);
        return result;
    }

    protected List<List<dynamic>> ExecuteMultiQuery(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        var datas = new List<List<dynamic>>();
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        return _connection.ExecuteMultiQuery(scName, spName, dynamicParameters);
    }

    protected T? QuerySingleSystemTable<T>(string sp_name, DynamicParameters parameters) where T : SysEntity
    {
        parameters = getParamForProc("dbo", sp_name, parameters);
        var result = _connection.ExecuteQuery<T>("dbo", sp_name, parameters);
        return result.FirstOrDefault();
    }

    protected IEnumerable<T> QuerySystemTables<T>(string sp_name, DynamicParameters parameters) where T : SysEntity
    {
        parameters = getParamForProc("dbo", sp_name, parameters);
        var result = _connection.ExecuteQuery<T>("dbo", sp_name, parameters);
        return result;
    }

    protected virtual DynamicParameters getParamForProc(string scName, string spName, DynamicParameters parameters)
    {
        DynamicParameters result = new DynamicParameters();

        DynamicParameters getProcParameters = new DynamicParameters();
        getProcParameters.Add("@scName", scName);
        getProcParameters.Add("@spName", spName);
        IEnumerable<dynamic> listParams = _connection.ExecuteQuery("dbo", "asGetProcedureParameters", getProcParameters);

        foreach (dynamic paramItem in listParams)
        {
            ParameterDirection direction = paramItem.PARAMETER_MODE.ToString() == "IN" ? ParameterDirection.Input : ParameterDirection.InputOutput;
            string parameter_name = paramItem.PARAMETER_NAME.ToString() ?? "";
            string data_type = paramItem.DATA_TYPE.ToString() ?? "";

            Type type = typeof(string);
            DbType dbType = DbType.String;
            switch (data_type.ToLower())
            {
                case "time":
                case "timestamp":
                    type = typeof(TimeOnly);
                    dbType = DbType.Time;
                    break;
                case "date":
                case "datetime2":
                case "datetimeoffset":
                case "smalldatetime":
                case "datetime":
                    type = typeof(DateTime);
                    dbType = DbType.DateTime;
                    break;
                case "text":
                case "ntext":
                case "varchar":
                case "char":
                case "nvarchar":
                case "nchar":
                    type = typeof(string);
                    dbType = DbType.String;
                    break;
                case "xml":
                    type = typeof(string);
                    dbType = DbType.Xml;
                    break;
                case "tinyint":
                case "smallint":
                case "int":
                    type = typeof(int);
                    dbType = DbType.Int32;
                    break;
                case "bigint":
                    type = typeof(int);
                    dbType = DbType.Int64;
                    break;
                case "money":
                case "float":
                case "decimal":
                case "numeric":
                case "smallmoney":
                case "real":
                    type = typeof(Decimal);
                    dbType = DbType.Decimal;
                    break;
                case "bit":
                    type = typeof(System.Boolean);
                    dbType = DbType.Boolean;
                    break;
                case "binary":
                    type = typeof(string);
                    dbType = DbType.Binary;
                    break;
                default:
                    type = typeof(string);
                    dbType = DbType.String;
                    break;
            }

            var exist = false;
            foreach (var paramName in parameters.ParameterNames)
            {
                if ("@p" + paramName.ToLower() == parameter_name.ToLower())
                {
                    object value = parameters.Get<object>(paramName);
                    result.Add(parameter_name, value, dbType, direction);
                    exist = true;
                    break;
                }
            }

            if (!exist)
            {
                result.Add(parameter_name, DefaultValues[type], dbType, direction);
            }
        }

        return result;
    }

    protected virtual DynamicParameters getParamForProc(string scName, string spName, JObject parameters)
    {
        DynamicParameters result = new DynamicParameters();

        DynamicParameters getProcParameters = new DynamicParameters();
        getProcParameters.Add("@scName", scName);
        getProcParameters.Add("@spName", spName);
        IEnumerable<dynamic> listParams = _connection.ExecuteQuery("dbo", "asGetProcedureParameters", getProcParameters);

        foreach (dynamic paramItem in listParams)
        {
            ParameterDirection direction = paramItem.PARAMETER_MODE.ToString() == "IN" ? ParameterDirection.Input : ParameterDirection.InputOutput;
            string parameter_name = paramItem.PARAMETER_NAME.ToString() ?? "";
            string data_type = paramItem.DATA_TYPE.ToString() ?? "";

            Type type = typeof(string);
            DbType dbType = DbType.String;
            switch (data_type.ToLower())
            {
                case "time":
                case "timestamp":
                    type = typeof(TimeOnly);
                    dbType = DbType.Time;
                    break;
                case "date":
                case "datetime2":
                case "datetimeoffset":
                case "smalldatetime":
                case "datetime":
                    type = typeof(DateTime);
                    dbType = DbType.DateTime;
                    break;
                case "text":
                case "ntext":
                case "varchar":
                case "char":
                case "nvarchar":
                case "nchar":
                    type = typeof(string);
                    dbType = DbType.String;
                    break;
                case "xml":
                    type = typeof(string);
                    dbType = DbType.Xml;
                    break;
                case "tinyint":
                case "smallint":
                case "int":
                    type = typeof(int);
                    dbType = DbType.Int32;
                    break;
                case "bigint":
                    type = typeof(int);
                    dbType = DbType.Int64;
                    break;
                case "money":
                case "float":
                case "decimal":
                case "numeric":
                case "smallmoney":
                case "real":
                    type = typeof(Decimal);
                    dbType = DbType.Decimal;
                    break;
                case "bit":
                    type = typeof(System.Boolean);
                    dbType = DbType.Boolean;
                    break;
                case "binary":
                    type = typeof(string);
                    dbType = DbType.Binary;
                    break;
                default:
                    type = typeof(string);
                    dbType = DbType.String;
                    break;
            }

            var exist = false;
            foreach(JProperty property in parameters.Properties())
            {
                var paramName = property.Name;
                var paramValue = property.Value.Value<object>();
                if ("@p" + paramName.ToLower() == parameter_name.ToLower())
                {
                    result.Add(parameter_name, paramValue, dbType, direction);
                    exist = true;
                    break;
                }
            }

            if (!exist)
            {
                result.Add(parameter_name, DefaultValues[type], dbType, direction);
            }
        }

        return result;
    }
}
