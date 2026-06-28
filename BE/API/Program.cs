using API;
using API.Common;
using API.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Reflection;



var builder = WebApplication.CreateBuilder(args);
var Configuration = builder.Configuration;

Utilities.Initialize(Configuration);

// Add services to the container.
Type type = typeof(DependencyInjection);
MethodInfo[] methods = type.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly);
foreach (var method in methods)
{
    if (method.GetParameters().Length == 2 && method.GetParameters()[0].ParameterType == typeof(IServiceCollection) && method.GetParameters()[1].ParameterType == typeof(IConfiguration))
    {
        method.Invoke(null, new object[] { builder.Services, Configuration });
    }
    if (method.GetParameters().Length == 1 && method.GetParameters()[0].ParameterType == typeof(IServiceCollection))
    {
        method.Invoke(null, new object[] { builder.Services });
    }
}

builder.Services.AddMvc();
builder.Services.AddControllers(options => { })
    .ConfigureApiBehaviorOptions(options => { })
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = null;
        options.JsonSerializerOptions.DictionaryKeyPolicy = null;
    })
    .AddNewtonsoftJson(options =>
    {
        options.SerializerSettings.ReferenceLoopHandling = Newtonsoft.Json.ReferenceLoopHandling.Ignore;
        //options.SerializerSettings.ContractResolver =
        //    new Newtonsoft.Json.Serialization.DefaultContractResolver
        //    {
        //        NamingStrategy = new Newtonsoft.Json.Serialization.SnakeCaseNamingStrategy()
        //    };
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "MapPlatform.API", Version = "v1" });
    c.AddSecurityDefinition("Bearer",
        new OpenApiSecurityScheme
        {
            Description = "JWT Authorization header using the Bearer scheme",
            Name = "Authorization",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.Http,
            BearerFormat = "JWT",
            Scheme = "Bearer"
        });
    c.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("bearer", document)] = []
    });
});


var app = builder.Build();

app.UseMiddleware<GlobalExceptionMiddleware>();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Base.API v1"));

    app.Use(async (context, next) =>
    {
        try
        {
            await next();
        }
        catch (Exception ex)
        {
            Utilities.Log(ex);
        }
    });
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();