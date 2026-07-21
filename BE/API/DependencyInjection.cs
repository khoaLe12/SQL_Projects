using API.Common;
using API.ExceptionHandling;
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

        // Register exception handlers (OCP-compliant services)
        services.AddSingleton<IExceptionHandler, ValidationExceptionHandler>();
        services.AddSingleton<IExceptionHandler, DefaultExceptionHandler>();
    }
}
