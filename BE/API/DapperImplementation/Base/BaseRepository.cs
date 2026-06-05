using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.VisualBasic;
using Newtonsoft.Json.Linq;
using API.Models.BaseModel;
using API.Models.SysEntities;
using System;
using System.Data;
using System.Drawing;
using System.Linq.Expressions;
using System.Reflection;
using System.Reflection.Emit;
using System.Runtime.CompilerServices;
using static Dapper.SqlMapper;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace API.DapperImplementation.Base;

public interface IBaseRepository {
    SysDictionary? GetDictionaryInformation(string code_name, string schema_name, string table_name);
    sysDAOInfo? GetDAOInformation(string code_name);
    void ExecuteNonQuery(string spName, ref DynamicParameters d);
    dynamic ExecuteScalar(string spName, ref DynamicParameters d);
    IEnumerable<dynamic> ExecuteQuery(string spName, ref DynamicParameters d);
    dynamic? ExecuteQuerySingle(string spName, ref DynamicParameters d);
    List<List<dynamic>> ExecuteMultiQuery(string spName, ref DynamicParameters d);
}

public class BaseRepository : IBaseRepository
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

    public BaseRepository(AdventureWorks2025Connection connection)
    {
        _connection = connection;
    }

    public SysDictionary? GetDictionaryInformation(string code_name, string schema_name, string table_name)
    {
        string sp_name = "asSysDictionaryGet";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("code_name", code_name);
        parameters.Add("schema_name", schema_name);
        parameters.Add("table_name", table_name);
        parameters = getParamForProc("dbo", sp_name, parameters);
        var result = _connection.ExecuteQuery<SysDictionary>("dbo", sp_name, parameters);
        return result.FirstOrDefault();
    }

    public sysDAOInfo? GetDAOInformation(string code_name)
    {
        string sp_name = "asSysDAOInfoGet";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("code_name", code_name);
        parameters = getParamForProc("dbo", sp_name, parameters);
        var result = _connection.ExecuteQuery<sysDAOInfo>("dbo", sp_name, parameters);
        return result.FirstOrDefault();
    }

    public void ExecuteNonQuery(string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc("dbo", spName, dynamicParameters);
        _connection.ExecuteNonQuery("dbo", spName, dynamicParameters);
    }

    public dynamic ExecuteScalar(string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc("dbo", spName, dynamicParameters);
        var result = _connection.ExecuteScalar("dbo", spName, dynamicParameters);
        return result;
    }

    public IEnumerable<dynamic> ExecuteQuery(string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc("dbo", spName, dynamicParameters);
        var result = _connection.ExecuteQuery("dbo", spName, dynamicParameters);
        return result;
    }

    public dynamic? ExecuteQuerySingle(string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc("dbo", spName, dynamicParameters);
        var result = _connection.ExecuteSingleOrDefault("dbo", spName, dynamicParameters);
        return result;
    }

    public List<List<dynamic>> ExecuteMultiQuery(string spName, ref DynamicParameters dynamicParameters)
    {
        var datas = new List<List<dynamic>>();
        dynamicParameters = getParamForProc("dbo", spName, dynamicParameters);
        return _connection.ExecuteMultiQuery("dbo", spName, dynamicParameters);
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

public interface IEntityRepository<T, TKeys> : IBaseRepository where T : BaseEntity where TKeys : EntityKey
{
    IEnumerable<T> QueryEntities(JObject search);
    IEnumerable<dynamic> ExecuteGet(JObject search);
    int ExecuteInsert(JObject data);
    int ExecuteUpdate(TKeys keys, JObject data);
    int ExecuteDelete(TKeys keys);
}

public class EntityRepository<T, TKeys> : BaseRepository, IEntityRepository<T, TKeys> where T : BaseEntity where TKeys : EntityKey
{
    private readonly SysDictionary _sysDictionary;
    private readonly sysDAOInfo _sysDAOInfo;
    private readonly string _schema;

    public EntityRepository(AdventureWorks2025Connection connection, string schema) : base (connection)
    {
        _schema = schema;
        
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
        var sysDictionary = GetDictionaryInformation("", _schema, nameof(T));
        if (sysDictionary is null)
        {
            throw new BaseADORepoException($"Table information is not declared, {nameof(sysDictionary)}");
        }
        var sysDAOInfo = GetDAOInformation(sysDictionary.code_name);
        if (sysDAOInfo is null)
        {
            throw new BaseADORepoException($"DAO information is not declared, {nameof(sysDAOInfo)}");
        }

        _sysDictionary = sysDictionary;
        _sysDAOInfo = sysDAOInfo;
    }

    public IEnumerable<T> QueryEntities(JObject search)
    {
        BeforeExecute();

        string sc_name = _sysDAOInfo.sp_schema;
        string sp_name = _sysDAOInfo.sp_get;

        DynamicParameters parameters = new DynamicParameters();
        foreach (JProperty property in search.Properties())
        {
            if (property.Value.Type == JTokenType.None || property.Value.Type == JTokenType.Null) continue;
            object? value = null;
            switch (property.Value.Type)
            {
                case JTokenType.Date:
                    value = property.Value.Value<DateTime>();
                    break;
                default:
                    value = property.Value.Value<string>();
                    break;
            }
            parameters.Add(property.Name, value);
        }
        parameters = getParamForProc(sc_name, sp_name, parameters);

        var result = _connection.ExecuteQuery<T>(sc_name, sp_name, parameters);

        AfterExecute();

        return result;
    }

    public IEnumerable<dynamic> ExecuteGet(JObject search)
    {
        BeforeExecute();

        string sc_name = _sysDAOInfo.sp_schema;
        string sp_name = _sysDAOInfo.sp_get;

        DynamicParameters parameters = new DynamicParameters();
        foreach(JProperty property in search.Properties())
        {
            if (property.Value.Type == JTokenType.None || property.Value.Type == JTokenType.Null) continue;
            object? value = null;
            switch(property.Value.Type)
            {
                case JTokenType.Date:
                    value = property.Value.Value<DateTime>();
                    break;
                default:
                    value = property.Value.Value<string>();
                    break;
            }
            parameters.Add(property.Name, value);
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
            if (property.Value.Type == JTokenType.None || property.Value.Type == JTokenType.Null) continue;
            object? value = null;
            switch (property.Value.Type)
            {
                case JTokenType.Date:
                    value = property.Value.Value<DateTime>();
                    break;
                default:
                    value = property.Value.Value<string>();
                    break;
            }
            parameters.Add(property.Name, value);
        }
        parameters = getParamForProc(sc_name, sp_name, parameters);

        dynamic? result = _connection.ExecuteSingleOrDefault(sc_name, sp_name, parameters);
        if (result is not null)
        {
            IDictionary<string, object> resultMap = (IDictionary<string, object>)result;
            PropertyInfo[] keys = typeof(TKeys).GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (PropertyInfo key in keys)
            {
                string keyName = key.Name;
                object? keyValue = resultMap[keyName];
                if (keyValue is not null)
                {
                    data[keyName] = JToken.FromObject(keyValue ?? "");
                }
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
            if (property.Value.Type == JTokenType.None || property.Value.Type == JTokenType.Null) continue;
            object? value = null;
            switch (property.Value.Type)
            {
                case JTokenType.Date:
                    value = property.Value.Value<DateTime>();
                    break;
                default:
                    value = property.Value.Value<string>();
                    break;
            }
            parameters.Add(property.Name, value);
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


    
    protected virtual void BeforeExecute() { }
    protected virtual void AfterExecute() { }
}

public class BaseADORepoException : Exception
{
    public BaseADORepoException() : base() { }
    public BaseADORepoException(string? s) : base(s) { }

    public BaseADORepoException(string? message, Exception? innerException) : base(message, innerException) { }
}