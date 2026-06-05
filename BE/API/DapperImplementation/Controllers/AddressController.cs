using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using API.DapperImplementation.Services;
using API.Utilities;


// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace API.DapperImplementation.Controllers;

[Route("api/dapper/[controller]")]
[ApiController]
public class AddressController : ControllerBase
{
    private IAddressServices _addressService;

    public AddressController(IAddressServices addressServices)
    {
        _addressService = addressServices;
    }

    [Route("executeget")]
    [HttpGet, HttpPost]
    public IActionResult ExecuteGet([FromBody] object? obj)
    {
        JObject jObject = JObject.FromObject(obj ?? new object());
        var addresses = _addressService.ExecuteGet(jObject);
        return Ok(new ApiResult("00000", addresses, "Success"));
    }


    [Route("executeinsert")]
    [HttpPost]
    public IActionResult ExecuteInsert([FromBody] object obj)
    {
        JObject jObject = JObject.FromObject(obj);
        int resultInt = _addressService.ExecuteInsert(jObject);
        if (resultInt == 0)
        {
            return Ok(new ApiResult("00000", jObject, "Success"));
        }
        else
        {
            string message = "Failed";
            string statusCode = "99999";
            if (resultInt == 10001)
            {
                message = "State Province ID not found";
                statusCode = "10000";
            }
            return Ok(new ApiResult(statusCode, resultInt.ToString(), message));
        }
    }


    [Route("executeupdate")]
    [HttpPost]
    public IActionResult ExecuteUpdate([FromQuery] int addressId, [FromBody] object obj)
    {
        JObject jObject = JObject.FromObject(obj);
        int resultInt = _addressService.ExecuteUpdate(addressId, jObject);
        if (resultInt == 0)
        {
            jObject.Add("AddressId", addressId);
            return Ok(new ApiResult("00000", jObject, "Success"));
        }
        else
        {
            return Ok(new ApiResult(resultInt.ToString(), "", "Failed"));

        }
    }


    [Route("executedelete")]
    [HttpDelete]
    public IActionResult ExecuteDelete([FromQuery] int addressId)
    {
        int resultInt = _addressService.ExecuteDelete(addressId);
        if (resultInt == 0)
        {
            return Ok(new ApiResult("00000", "", "Success"));
        }
        else
        {
            return Ok(new ApiResult(resultInt.ToString(), "", "Failed"));

        }
    }
}
