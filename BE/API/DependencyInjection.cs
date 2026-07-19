using API.Common;
using API.Services;

namespace API.DependencyInjection;

public static partial class DependencyInjection
{
    public static void AddCoreDependencies(this IServiceCollection services)
    {
        services.AddSingleton<IKeyManager, KeyManager>();
        services.AddScoped<IJwtTokenProvider, JwtTokenProvider>();

        // Register SRP-compliant services
        services.AddScoped<IParameterBuilder, ParameterBuilder>();
        services.AddScoped<IResultMapper, ResultMapper>();
        services.AddScoped<IResponseBuilder, ResponseBuilder>();
    }
}
