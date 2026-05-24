using Newtonsoft.Json.Linq;
using System;
using System.Text;

namespace SQLAgent.ErrorsCatalog;

public static class ErrorsCatalog
{
    private enum InternalServerError
    {
        ExceptionEncountered = 0,
        ServerError = 1,
        Overhead = 2
    }
    private enum ExternalServiceError
    {
        ServiceNotAvailable = 0,
        ServiceTimeout = 1
    }
    private enum ServiceError
    {
        ServiceNotAvailable = 0,
        ServiceNotImplemented = 1
    }
    private enum RepositoryError
    {
        TransactionError = 0
    }
    private enum SqlError
    {
        DuplicateKeys = 0,
        KeysNotFound = 1,
        ForeignKeyNotFound = 2,
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
