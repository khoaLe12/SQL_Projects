using API.Common;
using API.DapperImplementation.Base;
using API.DapperImplementation.Services;
using Microsoft.AspNetCore.Mvc;

namespace API;

[Route("api/[controller]")]
[ApiController]
public class HomeController : BaseController
{
    private readonly IHomeServices _homeServices;

    public HomeController(IHomeServices homeServices, IJwtTokenProvider jwtTokenProvider, IKeyManager keyManager) : base(jwtTokenProvider, keyManager)
    {
        _homeServices = homeServices;
    }

    [Route("register")]
    [HttpPost]
    public IActionResult Register([FromBody] object obj)
    {
        ApiResult apiResult = _homeServices.Register(obj);
        return Ok(apiResult);
    }

    [Route("login")]
    [HttpPost]
    public IActionResult Login([FromBody] object obj)
    {
        ApiResult apiResult = _homeServices.Login(obj);
        return Ok(apiResult);
    }

    [Route("logout")]
    [HttpPost]
    public IActionResult Logout([FromBody] object obj)
    {
        _homeServices.Logout(obj);
        return Ok(new ApiResult("00000", "", ""));
    }

    [Route("authenticate")]
    [HttpGet]
    public IActionResult Authenticate()
    {
        return Ok(new ApiResult("00000", base.Transaction.ToObject(), ""));
    }
}