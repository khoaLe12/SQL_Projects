using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json.Linq;
using API.EFCoreImplementation;
using API.Models.Entities;
using System.Data;
using System.Linq.Expressions;
using System.Reflection;

namespace API.EFCoreImplementation.Services;

public interface IAddressServices
{
    DataTable ExecuteGet(JObject dataSearch);
    int ExecuteInsert(JObject data);
    int ExecuteUpdate(object[] keys, JObject data);
    int ExecuteDelete(object[] keys);
    IEnumerable<Address> GetAddresses(int startPage, int endPage, int quantity, int? addressId, string? city);
    DataTable ExecuteQuery(int? addressId, string? city, int skip, int take);
    Task<bool> InsertAddress(Address address);
    Task<bool> UpdateAddress(int addressId, Address updateAddress);
    Task<bool> DeleteAddress(int addressId);

}

public class AddressServices : IAddressServices
{
    private IUnitOfWork _unitOfWork;

    public AddressServices(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public DataTable ExecuteGet(JObject dataSearch)
    {
        return _unitOfWork.AddressRepository.ExecuteGet(dataSearch);
    }

    public int ExecuteInsert(JObject data)
    {
        return _unitOfWork.AddressRepository.ExecuteInsert(data);
    }

    public int ExecuteUpdate(object[] keys, JObject data)
    {
        return _unitOfWork.AddressRepository.ExecuteUpdate(keys, data);
    }

    public int ExecuteDelete(object[] keys)
    {
        return _unitOfWork.AddressRepository.ExecuteDelete(keys);
    }

    public DataTable ExecuteQuery(int? addressId, string? city, int skip, int take)
    {
        var expressions = new List<Expression>();
        ParameterExpression pe = Expression.Parameter(typeof(Address), "a");
        MethodInfo? containsMethod = typeof(string).GetMethod("Contains", new[] { typeof(string) });
        if (containsMethod is null) throw new Exception();
        if (addressId is not null)
        {
            expressions.Add(Expression.Equal(Expression.Property(pe, nameof(Address.AddressId)), Expression.Constant(addressId)));
        }
        if (city is not null)
        {
            expressions.Add(Expression.Call(Expression.Property(pe, nameof(Address.City)), containsMethod, Expression.Constant(city)));
        }

        Expression<Func<Address, bool>>? where = a => true;
        if (expressions.Count() > 0)
        {
            Expression combined = expressions.Aggregate((accumulate, next) => Expression.AndAlso(accumulate, next));
            where = Expression.Lambda<Func<Address, bool>>(combined, pe);
        }

        DataTable table = _unitOfWork.AddressRepository.ExecuteRawSQL(where, new List<string> { "AddressId", "AddressLine1", "AddressLine2", "City" }, skip, take);

        return table;
    }

    public IEnumerable<Address> GetAddresses(int startPage, int endPage, int quantity, int? addressId, string? city)
    {
        var includes = new Expression<Func<Address, object?>>[]
        {
            a => a.BusinessEntityAddresses
        };

        var expressions = new List<Expression>();
        ParameterExpression pe = Expression.Parameter(typeof(Address), "a");
        MethodInfo? containsMethod = typeof(string).GetMethod("Contains", new[] { typeof(string) });
        if (containsMethod is null) throw new Exception();
        if (addressId is not null)
        {
            expressions.Add(Expression.Equal(Expression.Property(pe, nameof(Address.AddressId)), Expression.Constant(addressId)));
        }
        if (city is not null)
        {
            expressions.Add(Expression.Call(Expression.Property(pe, nameof(Address.City)), containsMethod, Expression.Constant(city)));
        }

        Expression<Func<Address, bool>>? where = a => true;
        if (expressions.Count() > 0)
        {
            Expression combined = expressions.Aggregate((accumulate, next) => Expression.AndAlso(accumulate, next));
            where = Expression.Lambda<Func<Address, bool>>(combined, pe);
        }

        IQueryable<Address> addresses = _unitOfWork.AddressRepository
            .Get(where, includes)
            .AsNoTracking();

        if (quantity == 0) quantity = 10;
        if (startPage > 0) addresses = addresses.Skip((startPage - 1) * quantity);
        if (startPage > 0) addresses = addresses.Take((endPage - startPage + 1) * quantity);

        return addresses.ToList();
    }

    public async Task<bool> InsertAddress(Address address)
    {
        await _unitOfWork.AddressRepository.AddAsync(address);
        var result = await _unitOfWork.SaveChangesAsync();
        return result;
    }

    public async Task<bool> UpdateAddress(int addressId, Address updateAddress)
    {
        var existedAddress = _unitOfWork.AddressRepository.
            Get(a => a.AddressId == addressId)
            .FirstOrDefault();

        if (existedAddress is null)
        {
            return false; 
        }

        existedAddress.AddressLine1 = updateAddress.AddressLine1;
        existedAddress.AddressLine2 = updateAddress.AddressLine2;
        existedAddress.City = updateAddress.City;
        existedAddress.StateProvinceId = updateAddress.StateProvinceId;
        existedAddress.PostalCode = updateAddress.PostalCode;
        existedAddress.ModifiedDate = DateTime.Now;

        updateAddress = existedAddress;

        var result = await _unitOfWork.SaveChangesAsync();
        return result;
    }

    public async Task<bool> DeleteAddress(int addressId)
    {
        var existedAddress = _unitOfWork.AddressRepository.
            Get(a => a.AddressId == addressId)
            .FirstOrDefault();

        if (existedAddress is null)
        {
            return false;
        }

        _unitOfWork.AddressRepository.Remove(existedAddress);
        var result = await _unitOfWork.SaveChangesAsync();

        return result;
    }
}
