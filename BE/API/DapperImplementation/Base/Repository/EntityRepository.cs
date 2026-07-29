using API.Models.BaseModel;
using API.Models.SysEntities;
using Dapper;
using Newtonsoft.Json.Linq;
using System.Reflection;

namespace API.DapperImplementation.Base.Repository;

public interface IEntityRepository<T, TKeys> : IBaseRepository where T : BaseEntity where TKeys : EntityKey
{
    IEnumerable<T> QueryEntities(string sc_name, string sp_name, ref DynamicParameters parameters);
    IEnumerable<dynamic> ExecuteGet(string sc_name, string sp_name, ref DynamicParameters parameters);
    int ExecuteInsert(string sc_name, string sp_name, ref DynamicParameters parameters);
    int ExecuteUpdate(string sc_name, string sp_name, TKeys keys, ref DynamicParameters parameters);
    int ExecuteDelete(string sc_name, string sp_name, DynamicParameters parameters);

    IEnumerable<T> QueryEntities(string sc_name, string sp_name, JObject search);
    IEnumerable<dynamic> ExecuteGet(string sc_name, string sp_name, JObject search);
    int ExecuteInsert(string sc_name, string sp_name, JObject data);
    int ExecuteUpdate(string sc_name, string sp_name, TKeys keys, JObject data);
    int ExecuteDelete(string sc_name, string sp_name, TKeys keys);
}

public class EntityRepository<T, TKeys> : BaseRepository, IEntityRepository<T, TKeys> where T : BaseEntity where TKeys : EntityKey
{
    public EntityRepository(AdventureWorks2025Connection connection) : base(connection) { }


    public virtual IEnumerable<T> QueryEntities(string sc_name, string sp_name, ref DynamicParameters parameters)
    {
        var result = ExecuteQuery<T>(sc_name, sp_name, ref parameters);
        return result;
    }

    public virtual IEnumerable<dynamic> ExecuteGet(string sc_name, string sp_name, ref DynamicParameters parameters)
    {
        var result = ExecuteQuery(sc_name, sp_name, ref parameters);
        return result;
    }

    public virtual int ExecuteInsert(string sc_name, string sp_name, ref DynamicParameters parameters)
    {
        ExecuteNonQuery(sc_name, sp_name, ref parameters);
        return parameters.Get<int>("@pRet");
    }

    public virtual int ExecuteUpdate(string sc_name, string sp_name, TKeys keys, ref DynamicParameters parameters)
    {
        keys.AttachKeys(ref parameters);
        ExecuteNonQuery(sc_name, sp_name, ref parameters);
        return parameters.Get<int>("@pRet");
    }

    public virtual int ExecuteDelete(string sc_name, string sp_name, DynamicParameters parameters)
    {
        ExecuteNonQuery(sc_name, sp_name, ref parameters);
        return parameters.Get<int>("@pRet");
    }



    public virtual IEnumerable<T> QueryEntities(string sc_name, string sp_name, JObject search)
    {
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

        var result = ExecuteQuery<T>(sc_name, sp_name, ref parameters);
        return result;
    }

    public virtual IEnumerable<dynamic> ExecuteGet(string sc_name, string sp_name, JObject search)
    {
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
        return result;
    }

    public virtual int ExecuteInsert(string sc_name, string sp_name, JObject data)
    {
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
            foreach(KeyValuePair<string, object> item in resultMap)
            {
                data[item.Key] = JToken.FromObject(item.Value);
            }
        }

        return parameters.Get<int>("@pRet");
    }

    public virtual int ExecuteUpdate(string sc_name, string sp_name, TKeys keys, JObject data)
    {
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
        return parameters.Get<int>("@pRet");
    }

    public virtual int ExecuteDelete(string sc_name, string sp_name, TKeys keys)
    {
        DynamicParameters parameters = new DynamicParameters();
        keys.AttachKeys(ref parameters);

        ExecuteNonQuery(sc_name, sp_name, ref parameters);
        return parameters.Get<int>("@pRet");
    }
}

public class EntityRepoException : Exception
{
    public int _errorCode { get; }

    public EntityRepoException(int errorCode) : base()
    {
        _errorCode = errorCode;
    }

    public EntityRepoException(string? s, int errorCode) : base(s)
    {
        _errorCode = errorCode;
    }

    public EntityRepoException(string? message, Exception? innerException, int errorCode) : base(message, innerException)
    {
        _errorCode = errorCode;
    }
}