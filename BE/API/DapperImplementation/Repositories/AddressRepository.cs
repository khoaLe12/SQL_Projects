using API.DapperImplementation.Base;
using API.DapperImplementation.Base.Repository;
using API.Models.BaseModel;
using API.Models.Entities;
using Dapper;

namespace API.DapperImplementation.Repositories;

public partial interface IAddressRepository : IEntityRepository<Address, AddressKey>
{
}

public partial class AddressRepository : EntityRepository<Address, AddressKey>, IAddressRepository
{
    public AddressRepository(AdventureWorks2025Connection connection) : base(connection)
    {
    }

    public override int ExecuteDelete(string sc_name, string sp_name, AddressKey keys)
    {
        // Implement soft delete here to replace hard delete
        // ...

        return base.ExecuteDelete(sc_name, sp_name, keys);
    }
}
