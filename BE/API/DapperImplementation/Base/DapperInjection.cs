using API.DapperImplementation.Base;
using API.DapperImplementation.Repositories;
using API.DapperImplementation.Services;
using API.Models;
using System.Reflection;

namespace API.DependencyInjection;

public static partial class DependencyInjection
{
    public static IServiceCollection AddDapperDependencies(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<AdventureWorks2025Connection>(provider => new AdventureWorks2025Connection(configuration.GetConnectionString("MsSQLConnectionADONet") ?? throw new ArgumentException("Connection string not found")));
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IBaseRepository, BaseRepository>();
        services.AddScoped<IBaseService, BaseService>();
        services.AddScoped<IHomeRepository, HomeRepository>();
        services.AddScoped<IHomeServices, HomeServices>();

        services.AddScoped<IAddressRepository, AddressRepository>();
        services.AddScoped<IAddressServices, AddressServices>();

        services.AddScoped<IBusinessEntityAddressRepository, BusinessEntityAddressRepository>();

        return services;
    }
}
