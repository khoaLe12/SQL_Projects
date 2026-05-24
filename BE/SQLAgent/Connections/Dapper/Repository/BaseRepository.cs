using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Newtonsoft.Json.Linq;
using SQLAgent.Connections.EFCore.Repository;
using SQLAgent.Connections.Models;
using SQLAgent.Connections.SysModels;
using System.Data;
using System.Drawing;
using System.Linq.Expressions;
using System.Reflection;
using System.Reflection.Emit;
using System.Runtime.CompilerServices;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace SQLAgent.Connections.Dapper.Repository;

public abstract class RepositoryKey
{
    public void AttachKeys(ref DynamicParameters parameters)
    {
        PropertyInfo[] props = this.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
        foreach (PropertyInfo prop in props)
        {
            string name = prop.Name;
            object value = prop.GetValue(this) ?? "";
            parameters.Add(name, value);
        }
    }
}
public interface IBaseRepository<T, TKeys> where T : BaseEntity where TKeys : RepositoryKey
{
    IEnumerable<dynamic> ExecuteGet(JObject search);
    int ExecuteInsert(JObject data);
    int ExecuteUpdate(TKeys keys, JObject data);
    int ExecuteDelete(TKeys keys);
}
public class BaseRepository<T, TKeys> : IBaseRepository<T, TKeys> where T : BaseEntity where TKeys : RepositoryKey
{
    private readonly string _schema;
    private readonly sysDAOInfo _sysDAOInfo;
    private readonly AdventureWorks2025Connection _connection;

    private readonly Dictionary<Type, object> DefaultValues = new Dictionary<Type, object>
    {
        { typeof(string), "" },
        { typeof(int), 0 },
        { typeof(Decimal), 0.0 },
        { typeof(System.Boolean), false },
        { typeof(DateTime), new DateTime(1900, 1, 1) },
        { typeof(TimeOnly), new TimeOnly(0, 0, 0) }
    };


    public BaseRepository(AdventureWorks2025Connection connection, string schema)
    {
        _schema = schema;
        _connection = connection;

        // Check schema existence
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("Schema_name", schema);
        parameters = getParamForProc("dbo", "asCheckSchemaName", parameters);
        _connection.ExecuteNonQuery("dbo", "asCheckSchemaName", parameters);
        if (parameters.Get<int>("@pRet") != 0)
        {
            throw new BaseADORepoException($"Schema {schema} not exists");
        }
        
        // Retrieve system information
        SysEntity? sysEntity = _connection.QuerySysEntity(typeof(sysDAOInfo), typeof(T), _schema);
        if (sysEntity is not null && sysEntity is sysDAOInfo)
            _sysDAOInfo = (sysDAOInfo)sysEntity;
        else
            _sysDAOInfo = new sysDAOInfo();
    }

    public IEnumerable<dynamic> ExecuteGet(JObject search)
    {
        BeforeExecute();

        string sc_name = _sysDAOInfo.sp_schema;
        string sp_name = _sysDAOInfo.sp_get;

        DynamicParameters parameters = new DynamicParameters();
        foreach(JProperty property in search.Properties())
        {
            parameters.Add(property.Name, property.Value.Value<object>());
        }
        parameters = getParamForProc(sc_name, sp_name, parameters);

        var result = _connection.ExecuteQuery(sc_name, sp_name, parameters);

        AfterExecute();

        return result;
    }

    public int ExecuteInsert(JObject data)
    {
        BeforeExecute();

        string sc_name = _sysDAOInfo.sp_schema;
        string sp_name = _sysDAOInfo.sp_ins;

        DynamicParameters parameters = new DynamicParameters();
        foreach (JProperty property in data.Properties())
        {
            parameters.Add(property.Name, property.Value.Value<object>());
        }
        parameters = getParamForProc(sc_name, sp_name, parameters);

        dynamic? result = _connection.ExecuteQuery(sc_name, sp_name, parameters).FirstOrDefault();
        if (result is not null)
        {
            PropertyInfo[] keys = typeof(TKeys).GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (PropertyInfo key in keys)
            {
                string keyName = key.Name;
                data[keyName] = JToken.FromObject(result[keyName] ?? "");
            }
        }

        AfterExecute();
        return parameters.Get<int>("@pRet");
    }

    public int ExecuteUpdate(TKeys keys, JObject data)
    {
        BeforeExecute();

        string sc_name = _sysDAOInfo.sp_schema;
        string sp_name = _sysDAOInfo.sp_upd;

        DynamicParameters parameters = new DynamicParameters();
        keys.AttachKeys(ref parameters);
        foreach (JProperty property in data.Properties())
        {
            parameters.Add(property.Name, property.Value.Value<object>());
        }
        parameters = getParamForProc(sc_name, sp_name, parameters);

        _connection.ExecuteNonQuery(sc_name, sp_name, parameters);

        AfterExecute();
        return parameters.Get<int>("@pRet");
    }

    public int ExecuteDelete(TKeys keys)
    {
        BeforeExecute();

        string sc_name = _sysDAOInfo.sp_schema;
        string sp_name = _sysDAOInfo.sp_del;

        DynamicParameters parameters = new DynamicParameters();
        keys.AttachKeys(ref parameters);
        parameters = getParamForProc(sc_name, sp_name, parameters);

        _connection.ExecuteNonQuery(sc_name, sp_name, parameters);

        AfterExecute();
        return parameters.Get<int>("@pRet");
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
                    result.Add(parameter_name, parameters.Get<object>(paramName), dbType, direction);
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
    protected virtual void BeforeExecute() { }
    protected virtual void AfterExecute() { }
}

public class BaseADORepoException : Exception
{
    public BaseADORepoException() : base() { }
    public BaseADORepoException(string? s) : base(s) { }

    public BaseADORepoException(string? message, Exception? innerException) : base(message, innerException) { }
}