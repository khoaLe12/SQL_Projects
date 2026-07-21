using Newtonsoft.Json.Linq;
using System;
using System.Text;

namespace API.Common;

public static class ResultCode
{
    public static readonly string SUCCESS = "00000";
    public static readonly string INVALID_INPUT = "80001";



    private static readonly Dictionary<string, string> InsertMessageMapping =
        new Dictionary<string, string>
        {
            { "10000", "Permission insufficient" },
            { "10001", "Duplicate key found" },
            { "10010", "Foreign key not found" },
            { "12627", "Insert duplicate key" },
            { "10547", "Insert foreign key not found" },
            { "10515", "Insert null value" },
            { "10229", "No Insert right" }
        };

    private static readonly Dictionary<string, string> UpdateMessageMapping =
        new Dictionary<string, string>
        {
            { "20000", "Permission insufficient" },
            { "20001", "Duplicate key found" },
            { "20010", "Foreign key not found" },
            { "22627", "Update duplicate key" },
            { "20547", "Update foreign key not found" },
            { "20515", "Update null value" },
            { "20229", "No Update right" }
        };

    private static readonly Dictionary<string, string> DeleteMessageMapping =
        new Dictionary<string, string>
        {
            { "30000", "Permission insufficient" },
            { "30229", "No Delete right" },
            { "30547", "Reference constraint violation" }
        };

    private static readonly Dictionary<string, string> RepositoryErrorMapping = 
        new Dictionary<string, string>
        {
            { "50000", "Repository Error" },
            { "50001", "Schema not existed" },
            { "50002", "Table information is not declared" },
            { "50003", "DAO information is not declared" },
        };

    private static readonly Dictionary<string, string> ServiceErrorMapping = 
        new Dictionary<string, string>
        {
            { "60000", "Service Error" },
            { "60001", "DAO information is not declared" },
            { "60010", "Repository is not registered" },
            { "60011", "UnitOfWork is not registered" },
            { "60012", "ParameterBuilder is not registered" },
            { "60013", "ResultMapper is not registered" },
        };

    private static readonly Dictionary<string, string> BadRequestMapping =
        new Dictionary<string, string>
        {
            { "80000", "Bad Request" },
            { "80001", "Invalid Input" }
        };



    public static string GetInsertResultCode(int returnCode)
    {
        return (10000 + returnCode).ToString("D5");
    }
    public static string GetUpdateResultCode(int returnCode)
    {
        return (20000 + returnCode).ToString("D5");
    }
    public static string GetDeleteResultCode(int returnCode)
    {
        return (30000 + returnCode).ToString("D5");
    }
    public static string GetRepositoryErrorCode(int returnCode)
    {
        return (50000 + returnCode).ToString("D5");
    }
    public static string GetServiceErrorCode(int returnCode)
    {
        return (60000 + returnCode).ToString("D5");
    }



    public static string GetInsertMessage(string resultCode)
    {
        return InsertMessageMapping.GetValueOrDefault(resultCode, "Insert operation failed");
    }
    public static string GetUpdateMessage(string resultCode)
    {
        return UpdateMessageMapping.GetValueOrDefault(resultCode, "Update operation failed");
    }
    public static string GetDeleteMessage(string resultCode)
    {
        return DeleteMessageMapping.GetValueOrDefault(resultCode, "Delete operation failed");
    }
    public static string GetRepositoryErrorMessage(string resultCode)
    {
        return RepositoryErrorMapping.GetValueOrDefault(resultCode, "Repository operation failed");
    }
    public static string GetServiceErrorMessage(string resultCode)
    {
        return ServiceErrorMapping.GetValueOrDefault(resultCode, "Service operation failed");
    }
    public static string GetBadRequestMessage(string resultCode)
    {
        return BadRequestMapping.GetValueOrDefault(resultCode, "Bad Request");
    }




    public static int GetHttpStatusCode(string resultCode)
    {
        if (resultCode == SUCCESS)
        {
            return StatusCodes.Status200OK;
        }

        if (resultCode.StartsWith("1") || resultCode.StartsWith("2") || resultCode.StartsWith("3"))
        {
            return StatusCodes.Status400BadRequest;
        }
        
        if (resultCode.StartsWith("5"))
        {
            return StatusCodes.Status500InternalServerError;
        }

        if (resultCode.StartsWith("6"))
        {
            return StatusCodes.Status500InternalServerError;
        }

        if (resultCode.StartsWith("8"))
        {
            return StatusCodes.Status400BadRequest;
        }

        return StatusCodes.Status400BadRequest; // Default to client error for unknown codes
    }
}
