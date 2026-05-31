using Microsoft.Data.SqlClient;
using SQLAgent.EFCoreImplementation;
using SQLAgent.Models.Entities;
using System.Data;
using System.Data.Common;

namespace SQLAgent.EFCoreImplementation.Repositories;

public partial interface IAddressRepository : IBaseRepository<Address, object[]>
{
}

public partial class AddressRepository : BaseRepository<Address, object[]>, IAddressRepository
{
    public AddressRepository(AdventureWorks2025Context applicationDbContext) : base(applicationDbContext)
    {
    }
}
