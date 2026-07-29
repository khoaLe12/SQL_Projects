using API.Common;
using API.DapperImplementation.Base.Repository;
using API.Models;
using API.Models.BaseModel;
using Microsoft.Extensions.DependencyInjection;
using System;
using static Dapper.SqlMapper;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;

namespace API.DapperImplementation.Base;

public interface IUnitOfWork<T> where T : IBaseRepository
{
    public TRepo? Repository<TRepo>() where TRepo : T;
    public void BeginTrans();
    public void CommitTrans();
    void RollbackTrans();
    void Dispose();
}

public sealed class UnitOfWork<T> : IUnitOfWork<T> where T : IBaseRepository
{
    private static readonly object UnitOfWorkLock = new object();

    private readonly IServiceProvider _provider;
    private readonly AdventureWorks2025Connection _connection;
    private Dictionary<Type, T> _repositoryDictionatyCache = new Dictionary<Type, T>();

    public UnitOfWork(IServiceProvider provider, AdventureWorks2025Connection connection)
    {
        _connection = connection;
        _provider = provider;
    }

    public TRepo? Repository<TRepo>() where TRepo : T
    {
        try
        {
            var key = typeof(TRepo);
            if (!_repositoryDictionatyCache.TryGetValue(key, out T? repo))
            {
                // Avoid the possibility of modifying the cache dictionary while another thread is accessing it
                lock (UnitOfWorkLock)
                {
                    if (!_repositoryDictionatyCache.TryGetValue(key, out repo))
                    {
                        // Resolve the concrete implementation for the requested repository interface
                        var resolved = (T)_provider.GetRequiredService(key);
                        _repositoryDictionatyCache[key] = resolved;
                        repo = resolved;
                    }
                }
            }

            return (TRepo?)repo;
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
