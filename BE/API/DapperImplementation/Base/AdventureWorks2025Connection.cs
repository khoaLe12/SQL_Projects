using Dapper;
using Microsoft.Data.SqlClient;
using Newtonsoft.Json.Linq;
using API.Models;
using System.Data;
using System.Globalization;
using System.Linq.Expressions;
using static Dapper.SqlMapper;

namespace API.DapperImplementation.Base;

public sealed class AdventureWorks2025Connection : IDisposable
{
    private readonly IDbConnection _db;
    private readonly SqlConnection _connection;
    private IDbTransaction? _transaction;

    public AdventureWorks2025Connection(string connectionString)
    {
        _db = new SqlConnection(connectionString);
        _connection = (SqlConnection)_db;
    }


    internal void BeginTrans()
    {
        _db.Open();
        _transaction = _db.BeginTransaction();
    }

    internal void CommitTrans()
    {
        if (_transaction is not null)
        {
            _transaction.Commit();
            _transaction.Dispose();
        }
        if (_connection.State == ConnectionState.Open)
        {
            _db.Close();
        }
    }

    internal void RollbackTrans()
    {
        if (_transaction is not null)
        {
            _transaction.Rollback();
            _transaction.Dispose();
        }
    }

    internal void Close()
    {
        if (_transaction is not null)
        {
            _transaction.Dispose();
        }
        _db.Close();
    }

    public void Dispose()
    {
        if (_transaction is not null)
        {
            _transaction.Dispose(); 
        }
        _db.Dispose();
    }


    internal IEnumerable<T> ExecuteQuery<T>(string scName, string spName, DynamicParameters parameters)
    {
        var result = _db.Query<T>($"{scName}.{spName}", parameters, commandType: CommandType.StoredProcedure, transaction: _transaction);
        return result;
    }

    internal int ExecuteNonQuery (string scName, string spName, DynamicParameters parameters)
    {
        int resultInt = _db.Execute($"{scName}.{spName}", parameters, _transaction, commandType: CommandType.StoredProcedure);
        return resultInt;
    }

    internal dynamic ExecuteScalar (string scName, string spName, DynamicParameters parameters)
    {
        var result = _db.ExecuteScalar<dynamic>($"{scName}.{spName}", parameters, _transaction, commandType: CommandType.StoredProcedure);
        return result ?? "";
    }

    internal dynamic? ExecuteSingleOrDefault(string scName, string spName, DynamicParameters parameters)
    {
        var result = _db.QuerySingleOrDefault($"{scName}.{spName}", parameters, _transaction, commandType: CommandType.StoredProcedure);
        return result;
    }

    internal IEnumerable<dynamic> ExecuteQuery(string scName, string spName, DynamicParameters parameters)
    {
        var result = _db.Query($"{scName}.{spName}", parameters, commandType: CommandType.StoredProcedure, transaction: _transaction);
        return result;
    }

    internal List<List<dynamic>> ExecuteMultiQuery(string scName, string spName, DynamicParameters parameters)
    {
        var datas = new List<List<dynamic>>();
        using (var multi = _db.QueryMultiple($"{scName}.{spName}", parameters, commandType: CommandType.StoredProcedure, transaction: _transaction))
        {
            while (!multi.IsConsumed)
            {
                var data = multi.Read().ToList();
                datas.Add(data);
            }
        }
        return datas;
    }
}
