using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OpenApi;
using SQLAgent.Connections.EFCore.Models;
using SQLAgent.Services.EFCoreServices;
using System.Net;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace SQLAgent.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EFCoreController : ControllerBase
    {
        private readonly IAddressServices _addressService;

        public EFCoreController(IAddressServices addressServices)
        {
            _addressService = addressServices;
        }


        [HttpGet("address/gettable")]
        public IActionResult GetTable([FromQuery] int skip, [FromQuery] int take, [FromQuery] int? addressId, [FromQuery] string? city)
        {
            var addresses = _addressService.ExecuteQuery(addressId, city, skip, take);
            return Ok(new ApiResult("00000", addresses, "Sucess"));
        }


        [HttpGet("address/get")]
        public IActionResult Get([FromQuery] int startPage, [FromQuery] int endPage, [FromQuery] int? quantity, [FromQuery] int? addressId, [FromQuery] string? city)
        {
            var addresses = _addressService.GetAddresses(startPage, endPage, quantity ?? 10, addressId, city);
            return Ok(new ApiResult("00000", addresses, "Sucess"));
        }


        [HttpPost("address/insert")]
        public async Task<IActionResult> Insert([FromBody] Address address)
        {
            var result = await _addressService.InsertAddress(address);
            if (result)
                return Ok(new ApiResult("00000", address, "Sucess"));
            else
                return Ok(new ApiResult("00001", "", "failed"));
        }


        [HttpPost("address/update/{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Address address)
        {
            var result = await _addressService.UpdateAddress(id, address);
            if (result)
                return Ok(new ApiResult("00000", address, "Sucess"));
            else
                return Ok(new ApiResult("00001", "", "failed"));
        }


        [HttpDelete("address/delete/{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var result = await _addressService.DeleteAddress(id);
            if (result)
                return Ok(new ApiResult("00000", "", "Sucess"));
            else
                return Ok(new ApiResult("00001", "", "failed"));
        }
    }
}