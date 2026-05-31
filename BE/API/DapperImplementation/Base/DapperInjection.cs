using SQLAgent.DapperImplementation.Base;
using SQLAgent.DapperImplementation.Repositories;
using SQLAgent.DapperImplementation.Services;
using SQLAgent.Models;

namespace SQLAgent.DependencyInjection;

public partial class DependencyInjection
{
    public static IServiceCollection AddDapperDependencies(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<AdventureWorks2025Connection>(provider => new AdventureWorks2025Connection(configuration.GetConnectionString("MsSQLConnectionADONet") ?? throw new ArgumentException("Connection string not found")));
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IBaseRepository, BaseRepository>();
        services.AddScoped<IBaseService, BaseService>();

        services.AddScoped<IAddressRepository, AddressRepository>();
        services.AddScoped<IAddressServices, AddressServices>();

        services.AddScoped<IBusinessEntityAddressRepository, BusinessEntityAddressRepository>();

        return services;
    }
}
