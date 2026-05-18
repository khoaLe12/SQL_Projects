using SQLAgent.Connections.EFCore.Data;
using SQLAgent.Connections.EFCore.Models;

namespace SQLAgent.Connections.EFCore.Repository;

public interface IAddressRepository : IBaseRepository<Address, object[]>
{
}

public class AddressRepository : BaseRepository<Address, object[]>, IAddressRepository
{
    public AddressRepository(AdventureWorks2025Context applicationDbContext) : base(applicationDbContext)
    {
    }
}
