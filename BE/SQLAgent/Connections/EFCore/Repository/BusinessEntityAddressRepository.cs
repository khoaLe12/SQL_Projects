using SQLAgent.Connections.EFCore.Data;
using SQLAgent.Connections.Models;

namespace SQLAgent.Connections.EFCore.Repository;

public partial interface IBusinessEntityAddressRepository : IBaseRepository<BusinessEntityAddress, object[]>
{
}

public partial class BusinessEntityAddressRepository : BaseRepository<BusinessEntityAddress, object[]>, IBusinessEntityAddressRepository
{
	public BusinessEntityAddressRepository(AdventureWorks2025Context adventureWorks2025Context) : base(adventureWorks2025Context)
	{
	}
}
