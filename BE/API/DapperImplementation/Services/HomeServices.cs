using API.Common;
using API.DapperImplementation.Repositories;
using API.Models.SysEntities;
using Newtonsoft.Json.Linq;

namespace API.DapperImplementation.Services;

public interface IHomeServices
{
    ApiResult Register(object data);
    ApiResult Login(object data);
    void Logout(object data);
}

public class HomeServices : IHomeServices
{
    private readonly IHomeRepository _homeRepository;
    private readonly IJwtTokenProvider _jwtTokenProvider;
    private readonly IKeyManager _keyManager;

    public HomeServices(IHomeRepository homeRepository, IJwtTokenProvider jwtTokenProvider, IKeyManager keyManager)
    {
        _homeRepository = homeRepository;
        _jwtTokenProvider = jwtTokenProvider;
        _keyManager = keyManager;
    }

    public ApiResult Register(object data)
    {
        ApiResult apiResult = new ApiResult();

        JToken token = JToken.FromObject(data);
        if (token is null || token.Type != JTokenType.Object)
        {
            apiResult.StatusCode = "50000";
            apiResult.Message = "Input not valid";
            return apiResult;
        }

        JObject? jObject = token as JObject;
        if (jObject is null ||
            !jObject.TryGetValue("username", out JToken? usernameToken) || usernameToken.Type != JTokenType.String ||
            !jObject.TryGetValue("password", out JToken? passwordToken) || passwordToken.Type != JTokenType.String ||
            usernameToken.Type == JTokenType.Null || passwordToken.Type == JTokenType.Null)
        {
            apiResult.StatusCode = "50000";
            apiResult.Message = "Input not valid";
            return apiResult;
        }

        string username = usernameToken.Value<string>()!;
        string password = passwordToken.Value<string>()!;
        if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
        {
            apiResult.StatusCode = "50000";
            apiResult.Message = "Input not valid";
            return apiResult;
        }

        string id = Guid.NewGuid().ToString();
        var result = _homeRepository.Register(id, username, Utilities.HashPassword(password));

        if (!result)
        {
            apiResult.StatusCode = "10000";
            apiResult.Message = "Register fail";
            return apiResult;
        }

        apiResult.StatusCode = "00000";
        apiResult.Message = "Register successfully";
        apiResult.Data = new
        {
            id = id,
        };
        return apiResult;
    }

    public ApiResult Login(object data)
    {
        ApiResult apiResult = new ApiResult();

        JObject jObject = JObject.FromObject(data);
        if (jObject is null ||
            !jObject.TryGetValue("username", out JToken? usernameToken) || usernameToken.Type != JTokenType.String ||
            !jObject.TryGetValue("password", out JToken? passwordToken) || passwordToken.Type != JTokenType.String ||
            usernameToken.Type == JTokenType.Null || passwordToken.Type == JTokenType.Null)
        {
            apiResult.StatusCode = "50000";
            apiResult.Message = "Input not valid";
            return apiResult;
        }

        (sysUserInfo? sysUserInfo, List<sysUserPrivilege> sysUserPrivileges) = _homeRepository.Login(usernameToken.Value<string>()!, Utilities.HashPassword(passwordToken.Value<string>()!));

        if (sysUserInfo is null)
        {
            apiResult.StatusCode = "10000";
            apiResult.Message = "Login fail";
            return apiResult;
        }

        apiResult.StatusCode = "00000";
        apiResult.Message = "Login successfully";
        apiResult.Data = new
        {
            username = usernameToken.Value<string>(),
            token = _jwtTokenProvider.CreateSecurityToken(sysUserInfo, sysUserPrivileges),
            apiKe = _keyManager.ApiKey
        };
        return apiResult;
    }

    public void Logout(object data)
    {

    }
}
