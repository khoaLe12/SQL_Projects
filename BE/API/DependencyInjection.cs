using API.Common;

namespace API.DependencyInjection;

public static partial class DependencyInjection
{
    public static void AddCoreDependencies(this IServiceCollection services)
    {
        services.AddSingleton<IKeyManager, KeyManager>();

        services.AddScoped<IJwtTokenProvider, JwtTokenProvider>();
    }
}
