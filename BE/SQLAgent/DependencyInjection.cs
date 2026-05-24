using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SQLAgent.Connections.Dapper;
using SQLAgent.Connections.EFCore.Data;
using SQLAgent.Connections.EFCore.Repository;
using SQLAgent.Services.EFCoreServices;

namespace SQLAgent;

public static class DependencyInjection
{
    public static IServiceCollection AddEFCoreDependencies(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<AdventureWorks2025Context>((sp, options) =>
        {
            options.UseSqlServer(configuration.GetConnectionString("MsSQLConnectionEFCore") ?? throw new ArgumentException("Connection string not found"), b =>
            {
                //b.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
            });
        });

        services.AddScoped<IUnitOfWork, UnitOfWork>();

        services.AddScoped<IAddressRepository, AddressRepository>();
        services.AddScoped<IBusinessEntityAddressRepository, BusinessEntityAddressRepository>();

        services.AddScoped<IAddressServices, AddressServices>();

        return services;
    }

    public static IServiceCollection AddADONetDependencies(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<AdventureWorks2025Connection>(provider => new AdventureWorks2025Connection(configuration.GetConnectionString("MsSQLConnectionADONet") ?? throw new ArgumentException("Connection string not found")));
        services.AddScoped<SQLAgent.Connections.Dapper.Data.IUnitOfWork, SQLAgent.Connections.Dapper.Data.UnitOfWork>();

        services.AddScoped<SQLAgent.Connections.Dapper.Repository.IAddressRepository, SQLAgent.Connections.Dapper.Repository.AddressRepository>();
        services.AddScoped<SQLAgent.Connections.Dapper.Repository.IBusinessEntityAddressRepository, SQLAgent.Connections.Dapper.Repository.BusinessEntityAddressRepository>();

        services.AddScoped<SQLAgent.Services.ADONetServices.IAddressServices, SQLAgent.Services.ADONetServices.AddressServices>();
        
        return services;
    }
}
