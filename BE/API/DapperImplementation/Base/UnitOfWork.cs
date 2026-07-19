using Microsoft.Extensions.DependencyInjection;
using API.Models;
using API.Common;
using System;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;

namespace API.DapperImplementation.Base;


public interface IUnitOfWork
{
    public IBaseRepository Repository(Type repository);
    public void BeginTrans();
    public void CommitTrans();
    void RollbackTrans();
    void Dispose();
}

public sealed class UnitOfWork : IUnitOfWork
{
    private static readonly object UnitOfWorkLock = new object();
    private readonly IServiceProvider _provider;
    private readonly AdventureWorks2025Connection _connection;
    private Dictionary<Type, IBaseRepository> _repositoryDictionatyCache = new Dictionary<Type, IBaseRepository>();

    public UnitOfWork(IServiceProvider provider, AdventureWorks2025Connection connection)
    {
        _connection = connection;
        _provider = provider;
    }

    public IBaseRepository Repository(Type repository)
    {
        try
        {
            if (!_repositoryDictionatyCache.TryGetValue(repository, out IBaseRepository? repo))
            {
                var baseGeneric = typeof(IEntityRepository<,>);
                if (!repository.GetInterfaces().Any(i => i.IsGenericType && i.GetGenericTypeDefinition() == baseGeneric))
                {
                    throw new InvalidOperationException($"Injected repository is invalid, {nameof(repository)}");
                }

                // Avoid the possibility of modifying the cache dictionary while another thread is accessing it
                lock (UnitOfWorkLock)
                {
                    repo = (IBaseRepository)_provider.GetRequiredService(repository);
                    _repositoryDictionatyCache[repository] = repo;
                }
            }
            return repo;
        }
        catch (Exception ex)
        {
            Common.Utilities.Log(ex);
            throw;
        }
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
