using API.DapperImplementation.Base;
using API.DapperImplementation.Repositories;
using API.DapperImplementation.Services;
using API.Models;
using System.Reflection;

namespace API.DependencyInjection;

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

        Type type = typeof(DependencyInjection);
        MethodInfo[] methods = type.GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly);
        foreach (var method in methods)
        {
            if (method.IsSpecialName || method.Name == nameof(AddDapperDependencies)) continue;

            if (method.GetParameters().Length == 2 && method.GetParameters()[0].ParameterType == typeof(IServiceCollection) && method.GetParameters()[1].ParameterType == typeof(IConfiguration))
            {
                method.Invoke(null, new object[] { services, configuration });
            }
            if (method.GetParameters().Length == 1 && method.GetParameters()[0].ParameterType == typeof(IServiceCollection))
            {
                method.Invoke(null, new object[] { services });
            }
        }

        return services;
    }
}
