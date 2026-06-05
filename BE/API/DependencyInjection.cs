using API.Utilities;

namespace API.DependencyInjection;

public static partial class DependencyInjection
{
    public static void AddCoreDependencies(this IServiceCollection services)
    {
        services.AddScoped<IKeyManager, KeyManager>();
    }
}
