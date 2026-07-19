using Dapper;
using Newtonsoft.Json.Linq;
using API.Models.SysEntities;
using API.Common;
using API.Services;

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
    protected readonly IUnitOfWork _unitOfWork;
    protected readonly IParameterBuilder _parameterBuilder;
    protected readonly IResultMapper _resultMapper;

    public BaseService(IUnitOfWork unitOfWork, IParameterBuilder parameterBuilder,
        IResultMapper resultMapper)
    {
        _unitOfWork = unitOfWork ?? throw new BaseADOServiceException(11);
        _parameterBuilder = parameterBuilder ?? throw new BaseADOServiceException(12);
        _resultMapper = resultMapper ?? throw new BaseADOServiceException(13);
    }

    public virtual ApiResult ExecuteGet(string code_name, JObject search)
    {
        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            throw new BaseADOServiceException(1);
        }

        // Delegate parameter building to specialized service
        DynamicParameters parameters = _parameterBuilder.Build(search);

        // Execute query
        var result = repository.ExecuteQuery(sysDAOInfo.sp_schema, sysDAOInfo.sp_get, ref parameters);

        // Delegate result mapping to specialized service
        return _resultMapper.MapQueryResult(result, "Get operation successful");
    }
    public virtual ApiResult ExecuteInsert(string code_name, JObject insert)
    {
        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            throw new BaseADOServiceException(1);
        }

        // Delegate parameter building to specialized service
        DynamicParameters parameters = _parameterBuilder.Build(insert);
        //_parameterBuilder.AddReturnParameter(parameters);

        // Execute insert stored procedure
        dynamic? keys = repository.ExecuteQuerySingle(sysDAOInfo.sp_schema, sysDAOInfo.sp_ins, ref parameters);
        int resultCode = parameters.Get<int>("@pRet");

        // Delegate result mapping to specialized service
        return _resultMapper.MapInsertResult(insert, keys, resultCode);
    }
    public virtual ApiResult ExecuteInsertArray(string code_name, JArray inserts)
    {
        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            throw new BaseADOServiceException(1);
        }

        _unitOfWork.BeginTrans();

        int resultInt = 0;

        List<JObject> results = new List<JObject>();
        foreach (JObject insert in inserts)
        {
            // Delegate parameter building to specialized service
            DynamicParameters parameters = _parameterBuilder.Build(insert);
            //_parameterBuilder.AddReturnParameter(parameters);

            dynamic? keys = repository.ExecuteQuerySingle(sysDAOInfo.sp_schema, sysDAOInfo.sp_ins, ref parameters);
            resultInt = parameters.Get<int>("@pRet");

            if (resultInt != 0)
            {
                _unitOfWork.RollbackTrans();
                break;
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
        return _resultMapper.MapBatchInsertResult(new JArray(results), resultInt);
    }
    public virtual ApiResult ExecuteUpdate(string code_name, JObject update)
    {
        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            throw new BaseADOServiceException(1);
        }

        // Delegate parameter building to specialized service
        DynamicParameters parameters = _parameterBuilder.Build(update);
        //_parameterBuilder.AddReturnParameter(parameters);

        // Execute update stored procedure
        repository.ExecuteNonQuery(sysDAOInfo.sp_schema, sysDAOInfo.sp_upd, ref parameters);
        int resultCode = parameters.Get<int>("@pRet");

        // Delegate result mapping to specialized service
        return _resultMapper.MapUpdateResult(resultCode, update);
    }
    public virtual ApiResult ExecuteDelete(string code_name, JObject delete)
    {
        IBaseRepository repository = _unitOfWork.Repository(typeof(IBaseRepository));
        sysDAOInfo? sysDAOInfo = repository.GetDAOInformation(code_name);
        if (sysDAOInfo is null)
        {
            throw new BaseADOServiceException(1);
        }

        // Delegate parameter building to specialized service
        DynamicParameters parameters = _parameterBuilder.Build(delete);
        //_parameterBuilder.AddReturnParameter(parameters);

        // Execute delete stored procedure
        repository.ExecuteNonQuery(sysDAOInfo.sp_schema, sysDAOInfo.sp_del, ref parameters);
        int resultCode = parameters.Get<int>("@pRet");

        // Delegate result mapping to specialized service
        return _resultMapper.MapDeleteResult(resultCode);
    }
}

public class BaseADOServiceException : Exception
{
    public int _errorCode { get; }

    public BaseADOServiceException(int errorCode) : base()
    {
        _errorCode = errorCode;
    }

    public BaseADOServiceException(string? s, int errorCode) : base(s)
    {
        _errorCode = errorCode;
    }

    public BaseADOServiceException(string? message, Exception? innerException, int errorCode) : base(message, innerException)
    {
        _errorCode = errorCode;
    }
}