using API.Models.BaseModel;
using API.Models.SysEntities;
using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.VisualBasic;
using Newtonsoft.Json.Linq;
using System;
using System.Data;
using System.Drawing;
using System.Linq.Expressions;
using System.Reflection;
using System.Reflection.Emit;
using System.Runtime.CompilerServices;
using System.Xml.Linq;
using static Dapper.SqlMapper;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace API.DapperImplementation.Base;

public interface IBaseRepository {
    SysDictionary? GetDictionaryInformation(string code_name, string schema_name, string table_name);
    sysDAOInfo? GetDAOInformation(string code_name);
    void ExecuteNonQuery(string scName, string spName, ref DynamicParameters d);
    dynamic ExecuteScalar(string scName, string spName, ref DynamicParameters d);
    IEnumerable<dynamic> ExecuteQuery(string scName, string spName, ref DynamicParameters d);
    dynamic? ExecuteQuerySingle(string scName, string spName, ref DynamicParameters d);
    List<List<dynamic>> ExecuteMultiQuery(string scName, string spName, ref DynamicParameters d);
}

public class BaseRepository : IBaseRepository
{
    protected readonly AdventureWorks2025Connection _connection;
    protected readonly Dictionary<Type, object> DefaultValues = new Dictionary<Type, object>
    {
        { typeof(string), "" },
        { typeof(int), 0 },
        { typeof(Decimal), 0.0 },
        { typeof(System.Boolean), false },
        { typeof(DateTime), new DateTime(1900, 1, 1) },
        { typeof(TimeOnly), new TimeOnly(0, 0, 0) }
    };

    public BaseRepository(AdventureWorks2025Connection connection)
    {
        _connection = connection;
    }

    // Hard code system table query in purpose of showing all available system tables

    public SysDictionary? GetDictionaryInformation(string code_name, string schema_name, string table_name)
    {
        string sp_name = "asSysDictionaryGet";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("code_name", code_name);
        parameters.Add("schema_name", schema_name);
        parameters.Add("table_name", table_name);
        parameters = getParamForProc("dbo", sp_name, parameters);
        var result = _connection.ExecuteQuery<SysDictionary>("dbo", sp_name, parameters);
        return result.FirstOrDefault();
    }

    public sysDAOInfo? GetDAOInformation(string code_name)
    {
        string sp_name = "asSysDAOInfoGet";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("code_name", code_name);
        parameters = getParamForProc("dbo", sp_name, parameters);
        var result = _connection.ExecuteQuery<sysDAOInfo>("dbo", sp_name, parameters);
        return result.FirstOrDefault();
    }

    public void ExecuteNonQuery(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        _connection.ExecuteNonQuery(scName, spName, dynamicParameters);
    }

    public dynamic ExecuteScalar(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        var result = _connection.ExecuteScalar(scName, spName, dynamicParameters);
        return result;
    }

    public IEnumerable<dynamic> ExecuteQuery(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        var result = _connection.ExecuteQuery(scName, spName, dynamicParameters);
        return result;
    }

    public dynamic? ExecuteQuerySingle(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        var result = _connection.ExecuteSingleOrDefault(scName, spName, dynamicParameters);
        return result;
    }

    public List<List<dynamic>> ExecuteMultiQuery(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        var datas = new List<List<dynamic>>();
        dynamicParameters = getParamForProc(scName, spName, dynamicParameters);
        return _connection.ExecuteMultiQuery(scName, spName, dynamicParameters);
    }


    protected virtual DynamicParameters getParamForProc(string scName, string spName, DynamicParameters parameters)
    {
        DynamicParameters result = new DynamicParameters();

        DynamicParameters getProcParameters = new DynamicParameters();
        getProcParameters.Add("@scName", scName);
        getProcParameters.Add("@spName", spName);
        IEnumerable<dynamic> listParams = _connection.ExecuteQuery("dbo", "asGetProcedureParameters", getProcParameters);

        foreach (dynamic paramItem in listParams)
        {
            ParameterDirection direction = paramItem.PARAMETER_MODE.ToString() == "IN" ? ParameterDirection.Input : ParameterDirection.InputOutput;
            string parameter_name = paramItem.PARAMETER_NAME.ToString() ?? "";
            string data_type = paramItem.DATA_TYPE.ToString() ?? "";

            Type type = typeof(string);
            DbType dbType = DbType.String;
            switch (data_type.ToLower())
            {
                case "time":
                case "timestamp":
                    type = typeof(TimeOnly);
                    dbType = DbType.Time;
                    break;
                case "date":
                case "datetime2":
                case "datetimeoffset":
                case "smalldatetime":
                case "datetime":
                    type = typeof(DateTime);
                    dbType = DbType.DateTime;
                    break;
                case "text":
                case "ntext":
                case "varchar":
                case "char":
                case "nvarchar":
                case "nchar":
                    type = typeof(string);
                    dbType = DbType.String;
                    break;
                case "xml":
                    type = typeof(string);
                    dbType = DbType.Xml;
                    break;
                case "tinyint":
                case "smallint":
                case "int":
                    type = typeof(int);
                    dbType = DbType.Int32;
                    break;
                case "bigint":
                    type = typeof(int);
                    dbType = DbType.Int64;
                    break;
                case "money":
                case "float":
                case "decimal":
                case "numeric":
                case "smallmoney":
                case "real":
                    type = typeof(Decimal);
                    dbType = DbType.Decimal;
                    break;
                case "bit":
                    type = typeof(System.Boolean);
                    dbType = DbType.Boolean;
                    break;
                case "binary":
                    type = typeof(string);
                    dbType = DbType.Binary;
                    break;
                default:
                    type = typeof(string);
                    dbType = DbType.String;
                    break;
            }

            var exist = false;
            foreach (var paramName in parameters.ParameterNames)
            {
                if ("@p" + paramName.ToLower() == parameter_name.ToLower())
                {
                    object value = parameters.Get<object>(paramName);
                    result.Add(parameter_name, value, dbType, direction);
                    exist = true;
                    break;
                }
            }

            if (!exist)
            {
                result.Add(parameter_name, DefaultValues[type], dbType, direction);
            }
        }

        return result;
    }
}

public class BaseADORepoException : Exception
{
    public int _errorCode { get; }

    public BaseADORepoException(int errorCode) : base()
    {
        _errorCode = errorCode;
    }

    public BaseADORepoException(string? s, int errorCode) : base(s)
    {
        _errorCode = errorCode;
    }

    public BaseADORepoException(string? message, Exception? innerException, int errorCode) : base(message, innerException)
    {
        _errorCode = errorCode;
    }
}