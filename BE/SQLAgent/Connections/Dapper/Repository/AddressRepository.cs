using SQLAgent.Connections.EFCore.Data;
using SQLAgent.Connections.Models;

namespace SQLAgent.Connections.Dapper.Repository;

public class AddressKey : RepositoryKey
{
    public int AddressID { get; set; }
    public AddressKey(int addressID)
    {
        AddressID = addressID;
    }
}

public partial interface IAddressRepository : IBaseRepository<Address, AddressKey>
{
}

public partial class AddressRepository : BaseRepository<Address, AddressKey>, IAddressRepository
{
    public AddressRepository(AdventureWorks2025Connection connection) : base(connection, "Person")
    {
    }
}
