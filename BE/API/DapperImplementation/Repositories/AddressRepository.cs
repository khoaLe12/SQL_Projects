using API.DapperImplementation.Base;
using API.Models.BaseModel;
using API.Models.Entities;
using Dapper;

namespace API.DapperImplementation.Repositories;

public class AddressKey : EntityKey
{
    public int AddressID { get; set; }
    public AddressKey(int addressID)
    {
        AddressID = addressID;
    }

    public override void AttachKeys(ref DynamicParameters parameters)
    {
        // Redefine how to attach keys
        base.AttachKeys(ref parameters);
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

    public override int ExecuteDelete(AddressKey keys)
    {
        // Implement soft delete here to replace hard delete
        // ...

        return base.ExecuteDelete(keys);
    }
}
