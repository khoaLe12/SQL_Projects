using Microsoft.Data.SqlClient;
using API.EFCoreImplementation;
using API.Models.Entities;
using System.Data;
using System.Data.Common;

namespace API.EFCoreImplementation.Repositories;

public partial interface IAddressRepository : IBaseRepository<Address, object[]>
{
}

public partial class AddressRepository : BaseRepository<Address, object[]>, IAddressRepository
{
    public AddressRepository(AdventureWorks2025Context applicationDbContext) : base(applicationDbContext)
    {
    }
}
