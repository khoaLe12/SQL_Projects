using SQLAgent.Connections.Models;

namespace SQLAgent.Connections.Dapper.Repository;

public class BusinessEntityAddressKey : RepositoryKey
{
    public int BusinessEntityID { get; set; }
    public int AddressID { get; set; }
    public int AddressTypeID { get; set; }
}

public partial interface IBusinessEntityAddressRepository : IBaseRepository<BusinessEntityAddress, BusinessEntityAddressKey>
{
}

public partial class BusinessEntityAddressRepository : BaseRepository<BusinessEntityAddress, BusinessEntityAddressKey>, IBusinessEntityAddressRepository
{
    public BusinessEntityAddressRepository(AdventureWorks2025Connection connection) : base(connection, "Person")
    {
    }
}