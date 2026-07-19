using API.Models.BaseModel;
using API.Models.SysEntities;
using Dapper;
using Newtonsoft.Json.Linq;
using System.Reflection;

namespace API.DapperImplementation.Base;

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
    protected readonly SysDictionary _sysDictionary;
    protected readonly sysDAOInfo _sysDAOInfo;
    protected readonly string _schema;

    public EntityRepository(AdventureWorks2025Connection connection, string schema) : base(connection)
    {
        _schema = schema;

        // Check schema existence
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("Schema_name", schema);
        ExecuteNonQuery("dbo", "asCheckSchemaName", ref parameters);
        if (parameters.Get<int>("@pRet") != 0)
        {
            throw new BaseADORepoException($"Schema {schema} not exists", 1);
        }

        // Retrieve system information
        var sysDictionary = GetDictionaryInformation("", _schema, typeof(T).Name);
        if (sysDictionary is null)
        {
            throw new BaseADORepoException($"Table information is not declared, {nameof(sysDictionary)}", 2);
        }
        var sysDAOInfo = GetDAOInformation(sysDictionary.code_name);
        if (sysDAOInfo is null)
        {
            throw new BaseADORepoException($"DAO information is not declared, {nameof(sysDAOInfo)}", 3);
        }

        _sysDictionary = sysDictionary;
        _sysDAOInfo = sysDAOInfo;
    }

    public virtual IEnumerable<T> QueryEntities(JObject search)
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

    public virtual IEnumerable<dynamic> ExecuteGet(JObject search)
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

        var result = ExecuteQuery(sc_name, sp_name, ref parameters);

        AfterExecute();

        return result;
    }

    public virtual int ExecuteInsert(JObject data)
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

        dynamic? result = ExecuteQuerySingle(sc_name, sp_name, ref parameters);
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

    public virtual int ExecuteUpdate(TKeys keys, JObject data)
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

        ExecuteNonQuery(sc_name, sp_name, ref parameters);

        AfterExecute();
        return parameters.Get<int>("@pRet");
    }

    public virtual int ExecuteDelete(TKeys keys)
    {
        BeforeExecute();

        string sc_name = _sysDAOInfo.sp_schema;
        string sp_name = _sysDAOInfo.sp_del;

        DynamicParameters parameters = new DynamicParameters();
        keys.AttachKeys(ref parameters);

        ExecuteNonQuery(sc_name, sp_name, ref parameters);

        AfterExecute();
        return parameters.Get<int>("@pRet");
    }



    protected virtual void BeforeExecute() { }
    protected virtual void AfterExecute() { }
}