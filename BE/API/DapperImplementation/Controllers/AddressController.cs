using API.Common;
using API.DapperImplementation.Base;
using API.DapperImplementation.Services;
using API.Services;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;

namespace API.DapperImplementation.Controllers;

/// <summary>
/// Address API controller.
/// Responsibility: Handle HTTP concerns and delegate to services.
/// Response building delegated to IResponseBuilder service.
/// </summary>
[Route("api/dapper/[controller]")]
[ApiController]
public class AddressController : ControllerBase
{
    private readonly IAddressServices _addressService;
    private readonly IResponseBuilder _responseBuilder;

    public AddressController(IAddressServices addressServices, IResponseBuilder responseBuilder)
    {
        _addressService = addressServices ?? throw new ArgumentNullException(nameof(addressServices));
        _responseBuilder = responseBuilder ?? throw new ArgumentNullException(nameof(responseBuilder));
    }

    [Route("executeget")]
    [HttpGet, HttpPost]
    public IActionResult ExecuteGet([FromBody] object? obj)
    {
        try
        {
            JObject jObject = JObject.FromObject(obj ?? new object());
            ApiResult apiResult = _addressService.ExecuteGet(jObject);
            return _responseBuilder.ToJsonResult(apiResult);
        }
        catch (Exception ex)
        {
            return _responseBuilder.HandleException(ex);
        }
    }

    [Route("executeinsert")]
    [HttpPost]
    public IActionResult ExecuteInsert([FromBody] object obj)
    {
        try
        {
            JObject jObject = JObject.FromObject(obj);
            ApiResult apiResult = _addressService.ExecuteInsert(jObject);
            return _responseBuilder.ToJsonResult(apiResult);
        }
        catch (Exception ex)
        {
            return _responseBuilder.HandleException(ex);
        }
    }

    [Route("executeupdate")]
    [HttpPost]
    public IActionResult ExecuteUpdate([FromQuery] int addressId, [FromBody] object obj)
    {
        try
        {
            JObject jObject = JObject.FromObject(obj);
            ApiResult apiResult = _addressService.ExecuteUpdate(addressId, jObject);
            return _responseBuilder.ToJsonResult(apiResult);
        }
        catch (Exception ex)
        {
            return _responseBuilder.HandleException(ex);
        }
    }

    [Route("executedelete")]
    [HttpDelete]
    public IActionResult ExecuteDelete([FromQuery] int addressId)
    {
        try
        {
            ApiResult apiResult = _addressService.ExecuteDelete(addressId);
            return _responseBuilder.ToJsonResult(apiResult);
        }
        catch (Exception ex)
        {
            return _responseBuilder.HandleException(ex);
        }
    }
}
