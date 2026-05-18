using SQLAgent.Connections.EFCore.Data;
using SQLAgent.Connections.EFCore.Models;

namespace SQLAgent.Connections.EFCore.Repository;

public interface IBusinessEntityAddressRepository : IBaseRepository<BusinessEntityAddress, object[]>
{
}

public class BusinessEntityAddressRepository : BaseRepository<BusinessEntityAddress, object[]>, IBusinessEntityAddressRepository
{
	public BusinessEntityAddressRepository(AdventureWorks2025Context adventureWorks2025Context) : base(adventureWorks2025Context)
	{
	}
}
