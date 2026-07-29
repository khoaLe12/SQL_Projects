using Dapper;
using Newtonsoft.Json.Linq;
using API.Models.SysEntities;
using API.Common;
using API.Services;
using API.DapperImplementation.Base.Repository;
using API.Models.BaseModel;
using System.Dynamic;
using System.Reflection;

namespace API.DapperImplementation.Base;

public interface IBaseService <T, TKey> where T : BaseEntity where TKey : EntityKey
{
    ApiResult ExecuteGet(JObject search);
    ApiResult ExecuteInsert(JObject insert);
    ApiResult ExecuteInsertArray(JArray inserts);
    ApiResult ExecuteUpdate(JObject update, TKey keys);
    ApiResult ExecuteDelete(TKey keys);
}

public abstract class BaseService<T, TKey> : IBaseService<T, TKey> where T : BaseEntity where TKey : EntityKey
{
    protected readonly IUnitOfWork<IEntityRepository<BaseEntity, EntityKey>> _unitOfWork;
    protected readonly IParameterBuilder _parameterBuilder;
    protected readonly IResultMapper _resultMapper;
    protected readonly ISystemRepository _systemRepository;
    private readonly sysDAOInfo _sysDAOInfo;
    private readonly SysDictionary _sysDictionary;

    public BaseService(
        ISystemRepository systemRepository, 
        IUnitOfWork<IEntityRepository<BaseEntity, EntityKey>> unitOfWork, 
        IParameterBuilder parameterBuilder, 
        IResultMapper resultMapper,
        string code_name)
    {
        _unitOfWork = unitOfWork ?? throw new BaseADOServiceException(11);
        _parameterBuilder = parameterBuilder ?? throw new BaseADOServiceException(12);
        _resultMapper = resultMapper ?? throw new BaseADOServiceException(13);
        _systemRepository = systemRepository ?? throw new BaseADOServiceException(14);

        sysDAOInfo? sysDAOInfo = _systemRepository.GetDAOInformation(code_name);
        SysDictionary? sysDictionary = _systemRepository.GetDictionaryInformation(code_name, "", "");
        _sysDAOInfo = sysDAOInfo ?? throw new BaseADOServiceException(15); ;
        _sysDictionary = sysDictionary ?? throw new BaseADOServiceException(15);        
    }

    public virtual ApiResult ExecuteGet(JObject search)
    {
        IEntityRepository<BaseEntity, EntityKey>? repository = _unitOfWork.Repository<IEntityRepository<BaseEntity, EntityKey>>();
        if (repository is null)
        {
            throw new BaseADOServiceException(10);
        }

        // Delegate parameter building to specialized service
        DynamicParameters parameters = _parameterBuilder.Build(search);

        // Execute query
        var result = repository.ExecuteGet(_sysDAOInfo.sp_schema, _sysDAOInfo.sp_get, ref parameters);

        // Delegate result mapping to specialized service
        return _resultMapper.MapQueryResult(result, null);
    }
    public virtual ApiResult ExecuteInsert(JObject insert)
    {
        IEntityRepository<BaseEntity, EntityKey>? repository = _unitOfWork.Repository<IEntityRepository<BaseEntity, EntityKey>>();
        if (repository is null)
        {
            throw new BaseADOServiceException(10);
        }

        // Execute insert stored procedure
        int resultCode = repository.ExecuteInsert(_sysDAOInfo.sp_schema, _sysDAOInfo.sp_ins, insert);

        // Extract keys
        var keys = new ExpandoObject() as IDictionary<string, object>;
        PropertyInfo[] keyMaps = typeof(TKey).GetProperties(BindingFlags.Public | BindingFlags.Instance);
        foreach (PropertyInfo property in keyMaps)
        {
            if (insert.TryGetValue(property.Name, out JToken? keyToken) && keyToken is not null)
            {
                keys.Add(property.Name, keyToken.Value<object>() ?? "");
            }
        }

        // Delegate result mapping to specialized service
        return _resultMapper.MapInsertResult(insert, keys, resultCode);
    }
    public virtual ApiResult ExecuteInsertArray(JArray inserts)
    {
        IEntityRepository<BaseEntity, EntityKey>? repository = _unitOfWork.Repository<IEntityRepository<BaseEntity, EntityKey>>();
        if (repository is null)
        {
            throw new BaseADOServiceException(10);
        }

        _unitOfWork.BeginTrans();

        bool success = true;
        int resultInt = 0;

        List<JObject> results = new List<JObject>();
        foreach (JObject insert in inserts)
        {
            int resultCode = repository.ExecuteInsert(_sysDAOInfo.sp_schema, _sysDAOInfo.sp_ins, insert);

            if (resultInt != 0)
            {
                _unitOfWork.RollbackTrans();
                success = false;
                break;
            }

            results.Add(insert);
        }

        if (success) _unitOfWork.CommitTrans();

        return _resultMapper.MapBatchInsertResult(new JArray(results), resultInt);
    }
    public virtual ApiResult ExecuteUpdate(JObject update, TKey keys)
    {
        IEntityRepository<BaseEntity, EntityKey>? repository = _unitOfWork.Repository<IEntityRepository<BaseEntity, EntityKey>>();
        if (repository is null)
        {
            throw new BaseADOServiceException(10);
        }

        // Delegate parameter building to specialized service
        DynamicParameters parameters = _parameterBuilder.Build(update);
        //_parameterBuilder.AddReturnParameter(parameters);

        // Execute update stored procedure
        int resultCode = repository.ExecuteUpdate(_sysDAOInfo.sp_schema, _sysDAOInfo.sp_upd, keys, ref parameters);

        // Delegate result mapping to specialized service
        return _resultMapper.MapUpdateResult(resultCode, update);
    }
    public virtual ApiResult ExecuteDelete(TKey keys)
    {
        IEntityRepository<BaseEntity, EntityKey>? repository = _unitOfWork.Repository<IEntityRepository<BaseEntity, EntityKey>>();
        if (repository is null)
        {
            throw new BaseADOServiceException(10);
        }

        // Execute delete stored procedure
        int resultCode =  repository.ExecuteDelete(_sysDAOInfo.sp_schema, _sysDAOInfo.sp_del, keys);

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