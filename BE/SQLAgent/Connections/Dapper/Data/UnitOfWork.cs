using SQLAgent.Connections.Dapper.Repository;

namespace SQLAgent.Connections.Dapper.Data;


public interface IUnitOfWork
{
    IAddressRepository AddressRepository { get; }
    IBusinessEntityAddressRepository BusinessEntityAddressRepository { get; }
    public void BeginTrans();
    public void CommitTrans();
    void RollbackTrans();
    void Dispose();
}

public class UnitOfWork : IUnitOfWork
{
    private readonly AdventureWorks2025Connection _connection;

    public IAddressRepository AddressRepository { get; private set; }

    public IBusinessEntityAddressRepository BusinessEntityAddressRepository { get; private set; }

    public UnitOfWork(AdventureWorks2025Connection connection,
        IAddressRepository addressRepository,
        IBusinessEntityAddressRepository businessEntityAddressRepository)
    {
        _connection = connection;
        AddressRepository = addressRepository;
        BusinessEntityAddressRepository = businessEntityAddressRepository;
    }

    public void BeginTrans()
    {
        _connection.BeginTrans();
    }

    public void CommitTrans()
    {
        _connection.CommitTrans();
    }

    public void RollbackTrans()
    {
        _connection.RollbackTrans();
    }

    public void Dispose()
    {
        _connection.Dispose();
    }
}
