using Microsoft.Data.SqlClient;
using SQLAgent.Connections.EFCore.Data;
using SQLAgent.Connections.Models;
using System.Data;
using System.Data.Common;

namespace SQLAgent.Connections.EFCore.Repository;

public partial interface IAddressRepository : IBaseRepository<Address, object[]>
{
}

public partial class AddressRepository : BaseRepository<Address, object[]>, IAddressRepository
{
    public AddressRepository(AdventureWorks2025Context applicationDbContext) : base(applicationDbContext)
    {
    }
}
