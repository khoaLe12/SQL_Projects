using Newtonsoft.Json.Linq;
using System;
using System.Text;

namespace API.Utilities;

public static class ErrorsCatalog
{
    private enum InternalServerError
    {
        InternalServerError = 0,
        ExceptionEncountered = 1,
        ServerError = 2,
        Overhead = 3
    }
    private enum ExternalServiceError
    {
        ExternalServiceError = 0,
        ServiceNotAvailable = 1,
        ServiceTimeout = 2
    }
    private enum ServiceError
    {
        ServiceError = 0,
        ServiceNotAvailable = 1,
        ServiceNotImplemented = 2
    }
    private enum RepositoryError
    {
        RepositoryError = 0,
        TransactionError = 1
    }
    private enum SqlError
    {
        SqlError = 0,
        DuplicateKeys = 1,
        KeysNotFound = 2,
        ForeignKeyNotFound = 3,
    }
    private enum ErrorCatalog
    {
        InternalServerError = 9,
        ExternalServiceError = 4,
        ServiceError = 3,
        RepositoryError = 2,
        SqlError = 1
    }

    public static string ErrorClassify(int errorCode)
    {
        if (errorCode < 9999 || errorCode > 99999)
        {
            return "Error";
        }

        int categoryDigit = int.Parse(errorCode.ToString()[0].ToString());
        int subCode = errorCode % 10000; // get 4 right most digits

        return categoryDigit switch
        {
            9 => Enum.GetName(typeof(InternalServerError), subCode) ?? "Error",
            4 => Enum.GetName(typeof(ExternalServiceError), subCode) ?? "Error",
            3 => Enum.GetName(typeof(ServiceError), subCode) ?? "Error",
            2 => Enum.GetName(typeof(RepositoryError), subCode) ?? "Error",
            1 => Enum.GetName(typeof(SqlError), subCode) ?? "Error",
            _ => "Error"
        };
    }
}
