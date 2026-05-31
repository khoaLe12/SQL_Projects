using Microsoft.EntityFrameworkCore;
using SQLAgent.EFCoreImplementation;
using SQLAgent.EFCoreImplementation.Repositories;
using SQLAgent.EFCoreImplementation.Services;
using System;

namespace SQLAgent.DependencyInjection;

public partial class DependencyInjection
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
}
