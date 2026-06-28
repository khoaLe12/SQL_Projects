using API.DapperImplementation.Base;
using API.Models.SysEntities;
using Dapper;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Text.Json;

namespace API.DapperImplementation.Repositories;

public interface IHomeRepository
{
    bool Register(string id, string username, string password);
    (sysUserInfo?, List<sysUserPrivilege>) Login(string username, string password);
}

public class HomeRepository : IHomeRepository
{
    protected readonly AdventureWorks2025Connection _connection;
    protected readonly Dictionary<Type, object> DefaultValues = new Dictionary<Type, object>
    {
        { typeof(string), "" },
        { typeof(int), 0 },
        { typeof(Decimal), 0.0 },
        { typeof(System.Boolean), false },
        { typeof(DateTime), new DateTime(1900, 1, 1) },
        { typeof(TimeOnly), new TimeOnly(0, 0, 0) }
    };

    public HomeRepository(AdventureWorks2025Connection connection)
    {
        _connection = connection;
    }

    public bool Register(string id, string username, string password)
    {
        string sp_name = "asRegisterAccount";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("id", id);
        parameters.Add("user_name", username);
        parameters.Add("password", password);
        parameters = getParamForProc("dbo", sp_name, parameters);
        _connection.ExecuteNonQuery("dbo", sp_name, parameters);
        int resultInt = parameters.Get<Int32>("@pRet");
        return resultInt == 0;
    }

    public (sysUserInfo?, List<sysUserPrivilege>) Login(string username, string password)
    {
        string sp_name = "asLoginAccount";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("user_name", username);
        parameters.Add("password", password);
        parameters = getParamForProc("dbo", sp_name, parameters);
        List<List<dynamic>> result = _connection.ExecuteMultiQuery("dbo", sp_name, parameters);

        sysUserInfo? userInfo = null;
        List<sysUserPrivilege> sysUserPrivileges = new List<sysUserPrivilege>();

        if (result.Count > 0)
        {
            var users = result[0];
            var json = JsonConvert.SerializeObject(users.FirstOrDefault());
            userInfo = JsonConvert.DeserializeObject<sysUserInfo>(json);
        }
        if (result.Count > 0)
        {
            var priviledges = result[1];
            var json = JsonConvert.SerializeObject(priviledges);
            sysUserPrivileges = JsonConvert.DeserializeObject<List<sysUserPrivilege>>(json) ?? new List<sysUserPrivilege>();
        }

        return (userInfo, sysUserPrivileges);
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
}
