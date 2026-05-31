using SQLAgent.EFCoreImplementation;
using SQLAgent.Models.Entities;

namespace SQLAgent.EFCoreImplementation.Repositories;

public partial interface IBusinessEntityAddressRepository : IBaseRepository<BusinessEntityAddress, object[]>
{
}

public partial class BusinessEntityAddressRepository : BaseRepository<BusinessEntityAddress, object[]>, IBusinessEntityAddressRepository
{
	public BusinessEntityAddressRepository(AdventureWorks2025Context adventureWorks2025Context) : base(adventureWorks2025Context)
	{
	}
}
