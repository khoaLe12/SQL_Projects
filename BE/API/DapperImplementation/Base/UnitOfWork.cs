using Microsoft.Extensions.DependencyInjection;
using SQLAgent.Models;
using SQLAgent.Utilities;
using System;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;

namespace SQLAgent.DapperImplementation.Base;


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
    private readonly IServiceProvider _provider;
    private readonly AdventureWorks2025Connection _connection;
    private Dictionary<Type, IBaseRepository> _repositoryDictionaty = new Dictionary<Type, IBaseRepository>();

    public UnitOfWork(IServiceProvider provider, AdventureWorks2025Connection connection)
    {
        _connection = connection;
        _provider = provider;
    }

    public IBaseRepository Repository(Type repository)
    {
        try
        {
            if (!_repositoryDictionaty.ContainsKey(repository))
            {
                var baseGeneric = typeof(IEntityRepository<,>);
                if (!repository.GetInterfaces().Any(i => i.IsGenericType && i.GetGenericTypeDefinition() == baseGeneric))
                {
                    throw new InvalidOperationException($"Injected repository is invalid, {nameof(repository)}");
                }

                var scopedService = (IBaseRepository)_provider.GetRequiredService(repository);
                _repositoryDictionaty.Add(repository, scopedService);
                return scopedService;
            }
            return _repositoryDictionaty[repository];
        }
        catch (Exception ex)
        {
            Utilities.Utilities.Log(ex);
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
