using SQLAgent.DapperImplementation.Base;
using SQLAgent.Models.BaseModel;
using SQLAgent.Models.Entities;

namespace SQLAgent.DapperImplementation.Repositories;

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
