using API.Common;
using API.DapperImplementation.Base;
using API.DapperImplementation.Repositories;
using API.Services;
using Newtonsoft.Json.Linq;

namespace API.DapperImplementation.Services;

public interface IAddressServices : IBaseService
{
    ApiResult ExecuteGet(JObject search);
    ApiResult ExecuteInsert(JObject data);
    ApiResult ExecuteUpdate(int addressId, JObject data);
    ApiResult ExecuteDelete(int addressId);
}

public class AddressServices : BaseService, IAddressServices
{
    public AddressServices(IUnitOfWork unitOfWork, IParameterBuilder parameterBuilder, 
        IResultMapper resultMapper) 
        : base(unitOfWork, parameterBuilder, resultMapper)
    {
    }

    public ApiResult ExecuteGet(JObject search)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADOServiceException(10);
        }
        var result = addressRepository.ExecuteGet(search);
        return _resultMapper.MapQueryResult(result);
    }

    public ApiResult ExecuteInsert(JObject data)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADOServiceException(10);
        }
        int resultInt = addressRepository.ExecuteInsert(data);
        return _resultMapper.MapInsertResult(data, null, resultInt);
    }

    public ApiResult ExecuteUpdate(int addressId, JObject data)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADOServiceException(10);
        }

        AddressKey key = new AddressKey(addressId);
        int resultInt = addressRepository.ExecuteUpdate(key, data);
        return _resultMapper.MapUpdateResult(resultInt, data);
    }

    public ApiResult ExecuteDelete(int addressId)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADOServiceException(10);
        }

        AddressKey key = new AddressKey(addressId);
        int resultInt = addressRepository.ExecuteDelete(key);
        return _resultMapper.MapDeleteResult(resultInt);
    }
}
