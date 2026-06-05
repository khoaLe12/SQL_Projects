using API.DapperImplementation.Base;
using API.Models.BaseModel;
using API.Models.Entities;

namespace API.DapperImplementation.Repositories;

public class BusinessEntityAddressKey : EntityKey
{
    public int BusinessEntityID { get; set; }
    public int AddressID { get; set; }
    public int AddressTypeID { get; set; }
}

public partial interface IBusinessEntityAddressRepository : IEntityRepository<BusinessEntityAddress, BusinessEntityAddressKey>
{
}

public partial class BusinessEntityAddressRepository : EntityRepository<BusinessEntityAddress, BusinessEntityAddressKey>, IBusinessEntityAddressRepository
{
    public BusinessEntityAddressRepository(AdventureWorks2025Connection connection) : base(connection, "Person")
    {
    }
}