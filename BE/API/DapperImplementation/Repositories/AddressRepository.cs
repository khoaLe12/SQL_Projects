using API.DapperImplementation.Base;
using API.Models.BaseModel;
using API.Models.Entities;

namespace API.DapperImplementation.Repositories;

public class AddressKey : EntityKey
{
    public int AddressID { get; set; }
    public AddressKey(int addressID)
    {
        AddressID = addressID;
    }
}

public partial interface IAddressRepository : IEntityRepository<Address, AddressKey>
{
}

public partial class AddressRepository : EntityRepository<Address, AddressKey>, IAddressRepository
{
    public AddressRepository(AdventureWorks2025Connection connection) : base(connection, "Person")
    {
    }
}
