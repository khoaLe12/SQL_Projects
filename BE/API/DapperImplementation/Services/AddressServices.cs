using Newtonsoft.Json.Linq;
using API.DapperImplementation.Base;
using API.DapperImplementation.Repositories;

namespace API.DapperImplementation.Services;

public interface IAddressServices
{
    IEnumerable<dynamic> ExecuteGet(JObject search);
    int ExecuteInsert(JObject data);
    int ExecuteUpdate(int addressId, JObject data);
    int ExecuteDelete(int addressId);
}

public class AddressServices : IAddressServices
{
    private readonly IUnitOfWork _unitOfWork;

    public AddressServices(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public IEnumerable<dynamic> ExecuteGet(JObject search)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADORepoException($"Repository not found, {nameof(addressRepository)}");
        }
        return addressRepository.ExecuteGet(search);
    }

    public int ExecuteInsert(JObject data)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADORepoException($"Repository not found, {nameof(addressRepository)}");
        }
        return addressRepository.ExecuteInsert(data);
    }

    public int ExecuteUpdate(int addressId, JObject data)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADORepoException($"Repository not found, {nameof(addressRepository)}");
        }

        AddressKey key = new AddressKey(addressId);
        return addressRepository.ExecuteUpdate(key, data);
    }

    public int ExecuteDelete(int addressId)
    {
        IAddressRepository? addressRepository = (IAddressRepository?)_unitOfWork.Repository(typeof(IAddressRepository));
        if (addressRepository is null)
        {
            throw new BaseADORepoException($"Repository not found, {nameof(addressRepository)}");
        }

        AddressKey key = new AddressKey(addressId);
        return addressRepository.ExecuteDelete(key);
    }
}
