using API.Common;
using API.DapperImplementation.Base;
using API.DapperImplementation.Base.Repository;
using API.DapperImplementation.Repositories;
using API.Models.BaseModel;
using API.Models.Entities;
using API.Services;
using Newtonsoft.Json.Linq;

namespace API.DapperImplementation.Services;

public interface IAddressServices : IBaseService<Address, AddressKey>
{
    ApiResult ExecuteUpdate(int addressId, JObject data);
    ApiResult ExecuteDelete(int addressId);
}

public class AddressServices : BaseService<Address, AddressKey>, IAddressServices
{
    public AddressServices(ISystemRepository systemRepository, IUnitOfWork<IEntityRepository<BaseEntity, EntityKey>> unitOfWork, IParameterBuilder parameterBuilder, 
        IResultMapper resultMapper) 
        : base(systemRepository, unitOfWork, parameterBuilder, resultMapper, "ADDRESS_CODE")
    {
    }

    public ApiResult ExecuteUpdate(int addressId, JObject data)
    {
        AddressKey key = new AddressKey(addressId);
        ApiResult apiResult = base.ExecuteUpdate(data, key);
        return apiResult;
    }

    public ApiResult ExecuteDelete(int addressId)
    {
        AddressKey key = new AddressKey(addressId);
        ApiResult apiResult = base.ExecuteDelete(key);
        return apiResult;
    }
}
