using API.EFCoreImplementation.Repositories;
using System.Linq.Expressions;

namespace API.EFCoreImplementation;

public interface IUnitOfWork
{
    IAddressRepository AddressRepository { get; }
    IBusinessEntityAddressRepository BusinessEntityAddressRepository { get; }
    Task<bool> SaveChangesAsync();
    void Dispose();
}
public class UnitOfWork : IUnitOfWork, IDisposable
{
    private readonly AdventureWorks2025Context _adventureWorks2025Context;

    public IAddressRepository AddressRepository { get; private set; }

    public IBusinessEntityAddressRepository BusinessEntityAddressRepository { get; private set; }

    public UnitOfWork(AdventureWorks2025Context adventureWorks2025Context,
        IAddressRepository addressRepository,
        IBusinessEntityAddressRepository businessEntityAddressRepository)
    {
            _adventureWorks2025Context = adventureWorks2025Context;
            AddressRepository = addressRepository;
            BusinessEntityAddressRepository = businessEntityAddressRepository;
    }

    public async Task<bool> SaveChangesAsync()
    {
        return (await _adventureWorks2025Context.SaveChangesAsync() > 0);
    }

    public void Dispose()
    {
        _adventureWorks2025Context?.Dispose();
    }
}
