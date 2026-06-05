using Dapper;
using Newtonsoft.Json.Linq;
using API.Models.SysEntities;
using API.Utilities;

namespace API.DapperImplementation.Base;

public interface IBaseService
{
    ApiResult ExecuteGet(string code_name, JObject search);
    ApiResult ExecuteInsert(string code_name, JObject insert);
    ApiResult ExecuteInsertArray(string code_name, JArray inserts);
    ApiResult ExecuteUpdate(string code_name, JObject update);
    ApiResult ExecuteDelete(string code_name, JObject delete);
}

public class BaseService : IBaseService
{
    private readonly IUnitOfWork _unitOfWork;

    public BaseService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public ApiResult ExecuteGet(string code_name, JObject search)
    {
        ApiResult apiResult = new ApiResult();

        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            apiResult.Message = "Get failed";
            apiResult.StatusCode = "10000";
            return apiResult;
        }

        DynamicParameters parameters = new DynamicParameters();
        foreach (JProperty property in search.Properties())
        {
            if (property.Type == JTokenType.Date)
            {
                parameters.Add(property.Name, property.Value.Value<DateTime>());
            }
            else
            {
                parameters.Add(property.Name, property.Value.ToString());
            }
        }

        var result = repository.ExecuteQuery(sysDAOInfo.sp_get, ref parameters);
        apiResult.Data = result;
        apiResult.StatusCode = "00000";
        apiResult.Message = "Get successful";
        return apiResult;
    }
    public ApiResult ExecuteInsert(string code_name, JObject insert)
    {
        ApiResult apiResult = new ApiResult();

        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            apiResult.Message = "Insert failed";
            apiResult.StatusCode = "10000";
            return apiResult;
        }
        DynamicParameters parameters = new DynamicParameters();
        foreach (JProperty property in insert.Properties())
        {
            if (property.Type == JTokenType.Date)
            {
                parameters.Add(property.Name, property.Value.Value<DateTime>());
            }
            else
            {
                parameters.Add(property.Name, property.Value.ToString());
            }
        }

        dynamic? keys = repository.ExecuteQuerySingle(sysDAOInfo.sp_ins, ref parameters);
        int resultInt = parameters.Get<int>("@pRet");
        if (resultInt != 0)
        {
            apiResult.StatusCode = "10000";
            apiResult.Data = resultInt.ToString();
            apiResult.Message = "Insert failed";
            return apiResult;
        }

        if (keys is not null)
        {
            IDictionary<string, object> keyMaps = (IDictionary<string, object>)keys;
            foreach (var key in keyMaps)
            {
                insert[key.Key] = JToken.FromObject(key.Value ?? "");
            }
        }

        apiResult.Data = insert;
        apiResult.StatusCode = "00000";
        apiResult.Message = "Insert successful";
        return apiResult;
    }
    public ApiResult ExecuteInsertArray(string code_name, JArray inserts)
    {
        try
        {
            ApiResult apiResult = new ApiResult();
            IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
            sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
            if (sysDAOInfo is null)
            {
                apiResult.Message = "Insert failed";
                apiResult.StatusCode = "10000";
                return apiResult;
            }

            _unitOfWork.BeginTrans();

            List<JObject> results = new List<JObject>();
            foreach (JObject insert in inserts)
            {
                DynamicParameters parameters = new DynamicParameters();
                foreach (JProperty property in insert.Properties())
                {
                    if (property.Type == JTokenType.Date)
                    {
                        parameters.Add(property.Name, property.Value.Value<DateTime>());
                    }
                    else
                    {
                        parameters.Add(property.Name, property.Value.ToString());
                    }
                }
                dynamic? keys = repository.ExecuteQuerySingle(sysDAOInfo.sp_ins, ref parameters);
                int resultInt = parameters.Get<int>("@pRet");
                if (resultInt != 0)
                {
                    _unitOfWork.RollbackTrans();
                    apiResult.StatusCode = "10000";
                    apiResult.Data = resultInt.ToString();
                    apiResult.Message = "Insert failed";
                    return apiResult;
                }
                if (keys is not null)
                {
                    IDictionary<string, object> keyMaps = (IDictionary<string, object>)keys;
                    foreach (var key in keyMaps)
                    {
                        insert[key.Key] = JToken.FromObject(key.Value ?? "");
                    }
                }
                results.Add(insert);
            }

            _unitOfWork.CommitTrans();

            apiResult.Data = results;
            apiResult.StatusCode = "00000";
            apiResult.Message = "Insert successful";
            return apiResult;
        }
        catch (Exception ex)
        {
            _unitOfWork.RollbackTrans();
            Utilities.Utilities.Log(ex);
            throw;
        }
    }
    public ApiResult ExecuteUpdate(string code_name, JObject update)
    {
        ApiResult apiResult = new ApiResult();
        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            apiResult.Message = "Update failed";
            apiResult.StatusCode = "10000";
            return apiResult;
        }

        DynamicParameters parameters = new DynamicParameters();
        foreach (JProperty property in update.Properties())
        {
            if (property.Type == JTokenType.Date)
            {
                parameters.Add(property.Name, property.Value.Value<DateTime>());
            }
            else
            {
                parameters.Add(property.Name, property.Value.ToString());
            }
        }

        repository.ExecuteNonQuery(sysDAOInfo.sp_upd, ref parameters);
        int resultInt = parameters.Get<int>("@pRet");
        if (resultInt != 0)
        {
            apiResult.StatusCode = "10000";
            apiResult.Data = resultInt.ToString();
            apiResult.Message = "Update failed";
            return apiResult;
        }

        apiResult.Data = update;
        apiResult.StatusCode = "00000";
        apiResult.Message = "Update successful";
        return apiResult;
    }
    public ApiResult ExecuteDelete(string code_name, JObject delete)
    {
        ApiResult apiResult = new ApiResult();
        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            apiResult.Message = "Delete failed";
            apiResult.StatusCode = "10000";
            return apiResult;
        }

        DynamicParameters parameters = new DynamicParameters();
        foreach (JProperty property in delete.Properties())
        {
            if (property.Type == JTokenType.Date)
            {
                parameters.Add(property.Name, property.Value.Value<DateTime>());
            }
            else
            {
                parameters.Add(property.Name, property.Value.ToString());
            }
        }

        repository.ExecuteNonQuery(sysDAOInfo.sp_del, ref parameters);
        int resultInt = parameters.Get<int>("@pRet");
        if (resultInt != 0)
        {
            apiResult.StatusCode = "10000";
            apiResult.Data = resultInt.ToString();
            apiResult.Message = "Delete failed";
            return apiResult;
        }

        apiResult.Data = delete;
        apiResult.StatusCode = "00000";
        apiResult.Message = "Delete successful";
        return apiResult;
    }
}
