using Newtonsoft.Json.Linq;
using SQLAgent.Connections.Dapper.Data;
using SQLAgent.Connections.Dapper.Repository;

namespace SQLAgent.Services.ADONetServices;

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
        return _unitOfWork.AddressRepository.ExecuteGet(search);
    }

    public int ExecuteInsert(JObject data)
    {
        return _unitOfWork.AddressRepository.ExecuteInsert(data);
    }

    public int ExecuteUpdate(int addressId, JObject data)
    {
        AddressKey key = new AddressKey(addressId);
        return _unitOfWork.AddressRepository.ExecuteUpdate(key, data);
    }

    public int ExecuteDelete(int addressId)
    {
        AddressKey key = new AddressKey(addressId);
        return _unitOfWork.AddressRepository.ExecuteDelete(key);
    }
}
