using Microsoft.AspNetCore.Components.Forms;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Newtonsoft.Json.Linq;
using SQLAgent.EFCoreImplementation;
using SQLAgent.Utilities;
using System;
using System.Collections;
using System.Collections.Immutable;
using System.Data;
using System.Data.Common;
using System.Linq.Expressions;
using System.Reflection;
using System.Text;
using static System.Runtime.InteropServices.JavaScript.JSType;
using SQLAgent.Models.SysEntities;
using SQLAgent.Models.BaseModel;

namespace SQLAgent.EFCoreImplementation.Repositories;

public interface IBaseRepository<T, TKeys> where T : BaseEntity where TKeys : IList<object>
{
    DataTable ExecuteGet(JObject search);
    int ExecuteInsert(JObject data);
    int ExecuteUpdate(TKeys keys, JObject data);
    int ExecuteDelete(TKeys keys);
    DataTable ExecuteRawSQL(Expression<Func<T, bool>>? where, List<string> columns, int skip, int take);
    Task<T?> FindAsync(TKeys keys);
    IQueryable<T> FindAll();
    IQueryable<T> GetAll(string entityTypeName);
    IQueryable<T> Get(Expression<Func<T, bool>> where);
    IQueryable<T> Get(Expression<Func<T, bool>> where, params Expression<Func<T, object?>>[] includes);
    IQueryable<T> Get(string entityTypeName, Expression<Func<T, bool>> where);
    Task AddAsync(T entity);
    Task AddAsync(T entity, string entityTypeName);
    Task AddRangeAsync(IEnumerable<T> entities);
    void Update(T entity);
    void Update(T entity, string entityTypeName);
    void Remove(T entity);
    void RemoveRange(IEnumerable<T> entities);
}

public class BaseRepository<T, TKeys> : IBaseRepository<T, TKeys> where T : BaseEntity where TKeys : IList<object>
{
    private readonly SysDictionary _sysDictionary;
    private readonly sysDAOInfo _sysDAOInfo;
    private readonly Dictionary<Type, object> defaultValues = new Dictionary<Type, object>
    {
        { typeof(string), "" },
        { typeof(int), 0 },
        { typeof(Decimal), 0.0 },
        { typeof(System.Boolean), false },
        { typeof(DateTime), new DateTime(1900, 1, 1) },
        { typeof(TimeOnly), new TimeOnly(0, 0, 0) }
    };

    protected readonly DbConnection _connection;
    protected readonly AdventureWorks2025Context _applicationDbContext;
    protected readonly DbSet<T> dbSet;

    public BaseRepository(AdventureWorks2025Context applicationDbContext)
    {
        _applicationDbContext = applicationDbContext;
        dbSet = _applicationDbContext.Set<T>();
        _connection = _applicationDbContext.Database.GetDbConnection();


        var entity = _applicationDbContext.Model.FindEntityType(typeof(T));
        string tableName = entity?.GetTableName() ?? "";
        string schema = entity?.GetSchema() ?? "";

        // Should use cache here or create a singleton service to store sys information
        SysDictionary? sysDictionary = _applicationDbContext.Set<SysDictionary>()
            .Where(d => d.schema_name == schema && d.table_name == tableName)
            .FirstOrDefault();
        if (sysDictionary is null)
        {
            throw new BaseEFRepoException($"Table information is not declared, {nameof(sysDictionary)}");
        }
        sysDAOInfo? dao = _applicationDbContext.Set<sysDAOInfo>()
            .Where(d => d.code_name == sysDictionary.code_name)
            .FirstOrDefault();
        if (dao is null)
        {
            throw new BaseEFRepoException($"DAO information is not declared, {nameof(dao)}");
        }

        _sysDictionary = sysDictionary;
        _sysDAOInfo = dao;
    }

    public virtual DataTable ExecuteGet(JObject search)
    {
        BeforeExecute();

        string sp_get = _sysDAOInfo.sp_get;
        string schema_name = _sysDAOInfo.sp_schema;

        DbCommand? dbCommand = null;
        try
        {
            _connection.Open();
            dbCommand = _connection.CreateCommand();

            List<DbParameter> parameters = new List<DbParameter>();
            foreach(JProperty property in search.Properties())
            {
                DbParameter parameter = dbCommand.CreateParameter();
                parameter.DbType = DbType.String;
                parameter.ParameterName = "@p" + property.Name.ToLower();

                string value = "";
                if (property.Type == JTokenType.Date)
                {
                    value = property.Value.Value<DateTime>().ToString("yyyy-MM-ddTHH:mm:ss");
                }
                else
                {
                    value = property.Value.Value<string>() ?? "";
                }
                parameter.Value = value;

                parameters.Add(parameter);
            }

            parameters = getParamForProc(schema_name, sp_get, parameters);
            dbCommand.CommandText = $"EXEC [{schema_name}].[{sp_get}] {string.Join(", ", parameters.Select(p => p.ParameterName))}";
            dbCommand.Parameters.AddRange(parameters.ToArray());
            DbDataReader dbDataReader = dbCommand.ExecuteReader();
            DataTable table = new DataTable();
            table.Load(dbDataReader);

            dbCommand.Dispose();
            _connection.Close();

            return table;
        }
        catch (Exception ex)
        {
            Utilities.Utilities.Log(ex);
            if (dbCommand is not null) dbCommand.Dispose();
            if (_connection.State == ConnectionState.Open) _connection.Close();
            throw;
        }
    }

    public virtual int ExecuteInsert(JObject data)
    {
        BeforeExecute();

        string sp_ins = _sysDAOInfo.sp_ins;
        string schema_name = _sysDAOInfo.sp_schema;

        DbCommand? dbCommand = null;
        try
        {
            _connection.Open();
            dbCommand = _connection.CreateCommand();

            List<DbParameter> parameters = new List<DbParameter>();
            foreach (JProperty property in data.Properties())
            {
                DbParameter parameter = dbCommand.CreateParameter();
                parameter.DbType = DbType.String;
                parameter.ParameterName = "@p" + property.Name.ToLower();

                string value = "";
                if (property.Type == JTokenType.Date)
                {
                    value = property.Value.Value<DateTime>().ToString("yyyy-MM-ddTHH:mm:ss");
                }
                else
                {
                    value = property.Value.Value<string>() ?? "";
                }
                parameter.Value = value;

                parameters.Add(parameter);
            }

            parameters = getParamForProc(schema_name, sp_ins, parameters);
            dbCommand.CommandText = $"EXEC [{schema_name}].[{sp_ins}] {string.Join(", ", parameters.Select(p =>
            {
                if (p.Direction == ParameterDirection.InputOutput || p.Direction == ParameterDirection.Output)
                {
                    return  $"{p.ParameterName} OUTPUT";
                }
                return p.ParameterName;
            }))}";
            dbCommand.Parameters.AddRange(parameters.ToArray());
            DbDataReader dbDataReader = dbCommand.ExecuteReader();

            int resultInt = (int?)dbCommand.Parameters["@pRet"].Value ?? 0;

            if (resultInt == 0)
            {
                DataTable table = new DataTable();
                table.Load(dbDataReader);
                var keys = table.Rows[0];

                var entity = _applicationDbContext.Model.FindEntityType(typeof(T));
                IKey? eKey = entity?.GetKeys().FirstOrDefault(e => e.IsPrimaryKey());
                if (eKey is not null)
                {
                    for (int i = 0; i < eKey.Properties.Count; i++)
                    {
                        var columnName = eKey.Properties.ElementAtOrDefault(i)?.Name ?? "";
                        if (table.Columns.Contains(columnName))
                        {
                            data[columnName] = JToken.FromObject(keys[columnName] ?? "");
                        }
                    }
                }
            }

            dbCommand.Dispose();
            _connection.Close();

            AfterExecute();
            return resultInt;
        }
        catch (Exception ex)
        {
            Utilities.Utilities.Log(ex);
            if (dbCommand is not null) dbCommand.Dispose();
            if (_connection.State == ConnectionState.Open) _connection.Close();
            throw;
        }
    }

    public virtual int ExecuteUpdate(TKeys keys, JObject data)
    {
        BeforeExecute();

        string sp_upd = _sysDAOInfo.sp_upd;
        string schema_name = _sysDAOInfo.sp_schema;

        DbCommand? dbCommand = null;
        try
        {
            _connection.Open();
            dbCommand = _connection.CreateCommand();

            List<DbParameter> parameters = new List<DbParameter>();
            foreach (JProperty property in data.Properties())
            {
                DbParameter parameter = dbCommand.CreateParameter();
                parameter.DbType = DbType.String;
                parameter.ParameterName = "@p" + property.Name.ToLower();

                string value = "";
                if (property.Type == JTokenType.Date)
                {
                    value = property.Value.Value<DateTime>().ToString("yyyy-MM-ddTHH:mm:ss");
                }
                else
                {
                    value = property.Value.Value<string>() ?? "";
                }
                parameter.Value = value;

                parameters.Add(parameter);
            }

            // Set keys
            int keysCount = keys.Count();
            var entity = _applicationDbContext.Model.FindEntityType(typeof(T));
            IKey[] eKeys = entity?.GetKeys()?.ToArray() ?? Array.Empty<IKey>();
            for (int i = 0; i < eKeys.Count(); i++)
            {
                if (keysCount > i)
                {
                    DbParameter parameter = dbCommand.CreateParameter();
                    parameter.DbType = DbType.String;
                    parameter.ParameterName = "@p" + eKeys[i].GetName() ?? "";

                    string value = "";
                    if (eKeys[i].GetType() == typeof(DateTime) && keys[i].GetType() == typeof(DateTime))
                    {
                        value = ((DateTime?)keys[i])?.ToString("yyyy-MM-ddTHH:mm:ss") ?? "1900-01-01";
                    }
                    else
                    {
                        value = keys[i]?.ToString() ?? "";
                    }
                    parameter.Value = value;

                    parameters.Add(parameter);
                }
            }

            parameters = getParamForProc(schema_name, sp_upd, parameters);
            dbCommand.CommandText = $"EXEC [{schema_name}].[{sp_upd}] {string.Join(", ", parameters.Select(p =>
            {
                if (p.Direction == ParameterDirection.InputOutput || p.Direction == ParameterDirection.Output)
                {
                    return $"{p.ParameterName} OUTPUT";
                }
                return p.ParameterName;
            }))}";
            dbCommand.Parameters.AddRange(parameters.ToArray());
            int rows = dbCommand.ExecuteNonQuery();

            int resultInt = (int?)dbCommand.Parameters["@pRet"].Value ?? 0;

            dbCommand.Dispose();
            _connection.Close();

            AfterExecute();
            return resultInt;
        }
        catch (Exception ex)
        {
            Utilities.Utilities.Log(ex);
            if (dbCommand is not null) dbCommand.Dispose();
            if (_connection.State == ConnectionState.Open) _connection.Close();
            throw;
        }
    }

    public virtual int ExecuteDelete(TKeys keys)
    {
        BeforeExecute();

        string sp_upd = _sysDAOInfo.sp_del;
        string schema_name = _sysDAOInfo.sp_schema;

        DbCommand? dbCommand = null;
        try
        {
            _connection.Open();
            dbCommand = _connection.CreateCommand();

            // Set keys
            List<DbParameter> parameters = new List<DbParameter>();
            int keysCount = keys.Count();
            var entity = _applicationDbContext.Model.FindEntityType(typeof(T));
            IKey[] eKeys = entity?.GetKeys()?.ToArray() ?? Array.Empty<IKey>();
            for (int i = 0; i < eKeys.Count(); i++)
            {
                if (keysCount > i)
                {
                    DbParameter parameter = dbCommand.CreateParameter();
                    parameter.DbType = DbType.String;
                    parameter.ParameterName = "@p" + eKeys[i].GetName() ?? "";

                    string value = "";
                    if (eKeys[i].GetType() == typeof(DateTime) && keys[i].GetType() == typeof(DateTime))
                    {
                        value = ((DateTime?)keys[i])?.ToString("yyyy-MM-ddTHH:mm:ss") ?? "1900-01-01";
                    }
                    else
                    {
                        value = keys[i]?.ToString() ?? "";
                    }
                    parameter.Value = value;

                    parameters.Add(parameter);
                }
            }

            parameters = getParamForProc(schema_name, sp_upd, parameters);
            dbCommand.CommandText = $"EXEC [{schema_name}].[{sp_upd}] {string.Join(", ", parameters.Select(p => p.ParameterName))}";
            dbCommand.Parameters.AddRange(parameters.ToArray());
            int rows = dbCommand.ExecuteNonQuery();

            int resultInt = (int?)dbCommand.Parameters["@pRet"].Value ?? 0;

            dbCommand.Dispose();
            _connection.Close();

            AfterExecute();
            return resultInt;
        }
        catch (Exception ex)
        {
            Utilities.Utilities.Log(ex);
            if (dbCommand is not null) dbCommand.Dispose();
            if (_connection.State == ConnectionState.Open) _connection.Close();
            throw;
        }
    }
    
    public virtual DataTable ExecuteRawSQL(Expression<Func<T, bool>>? where, List<string> columns, int skip, int take)
    {
        BeforeExecute();

        if (take == 0) take = 10;
        DbCommand? dbCommand = null;
        DbTransaction? transaction = null;
        try
        {
            Expression? whereCondition = null;
            ParameterExpression? whereParameter = null;
            if (where is not null)
            {
                if (where.Parameters.Count() == 0)
                {
                    throw new BaseEFRepoException();
                }
                if (where.Parameters.Count() > 1)
                {
                    throw new BaseEFRepoException();
                }
                whereCondition = where.Body;
                whereParameter = where.Parameters[0];
            }

            var entity = _applicationDbContext.Model.FindEntityType(typeof(T));
            if (entity is null)
            {
                throw new BaseEFRepoException();
            }

            string tableName = entity.GetTableName() ?? "";
            string schema = entity.GetSchema() ?? "";
            if (string.IsNullOrEmpty(tableName) || string.IsNullOrEmpty(schema))
            {
                throw new BaseEFRepoException();
            }

            StringBuilder stringBuilder = new StringBuilder();
            if (columns.Count() > 0)
            {
                foreach (var column in columns)
                {
                    var property = entity!.FindProperty(column);
                    if (property is null)
                    {
                        throw new BaseEFRepoException();
                    }
                    stringBuilder.Append(column + ",");
                }
                stringBuilder.Remove(stringBuilder.Length - 1, 1);
            }

            string whereClause = "";
            List<string> fields = new List<string>();
            if (whereCondition is not null && whereParameter is not null)
            {
                SqlExpressionVisitor visitor = new SqlExpressionVisitor();
                whereClause = (whereParameter.Name ?? "") + " WHERE " + visitor.Translate(whereCondition);
                fields = visitor.GetFields();
            }
            
            string orderByClause = "AddressId";
            if (fields.Count() > 0)
            {
                if (fields.Contains("city")) orderByClause = "city";
            }
            
            string rawSql = $"SELECT {stringBuilder.ToString()} FROM [{schema}].[{tableName}] {whereClause} ORDER BY {orderByClause} OFFSET {skip} ROWS FETCH NEXT {take} ROWS ONLY";

            _connection.Open();
            dbCommand = _connection.CreateCommand();
            transaction = _connection.BeginTransaction();

            dbCommand.CommandText = rawSql;
            dbCommand.Transaction = transaction;
            DbDataReader dbDataReader = dbCommand.ExecuteReader();
            var table = new DataTable();
            table.Load(dbDataReader);

            transaction.Commit();
            dbCommand.Dispose();
            _connection.Close();

            AfterExecute();
            return table;
        }
        catch (Exception ex)
        {
            Utilities.Utilities.Log(ex);
            if (transaction is not null) transaction.Rollback();
            if (dbCommand is not null) dbCommand.Dispose();
            if (_connection.State == ConnectionState.Open) _connection.Close();
            throw;
        }
    }

    public virtual async Task AddAsync(T entity)
    {
        await dbSet.AddAsync(entity);
    }

    public virtual async Task AddRangeAsync(IEnumerable<T> entities)
    {
        await dbSet.AddRangeAsync(entities);
    }

    public virtual async Task AddAsync(T entity, string entityTypeName)
    {
        await _applicationDbContext.Set<T>(entityTypeName).AddAsync(entity);
    }

    public virtual IQueryable<T> FindAll()
    {
        return dbSet.AsNoTracking();
    }

    public virtual async Task<T?> FindAsync(TKeys tkeys)
    {
        object[] keys = tkeys.ToArray();
        if (keys is null || keys.Length == 0) throw new Exception();
        return await dbSet.FindAsync(keys);
    }

    public virtual IQueryable<T> Get(Expression<Func<T, bool>> where)
    {
        return dbSet.Where(where);
    }

    public virtual IQueryable<T> Get(Expression<Func<T, bool>> where, params Expression<Func<T, object?>>[] includes)
    {
        var result = dbSet.Where(where);
        foreach (var include in includes)
        {
            result = result.Include(include);
        }
        return result;
    }

    public virtual IQueryable<T> Get(string entityTypeName, Expression<Func<T, bool>> where)
    {
        return _applicationDbContext.Set<T>(entityTypeName).Where(where);
    }

    public virtual void Remove(T entity)
    {
        dbSet.Remove(entity);
    }

    public virtual void RemoveRange(IEnumerable<T> entities)
    {
        dbSet.RemoveRange(entities);
    }

    public virtual void Update(T entity)
    {
        _applicationDbContext.Entry<T>(entity).State = EntityState.Modified;
    }

    public virtual IQueryable<T> GetAll(string entityTypeName)
    {
        return _applicationDbContext.Set<T>(entityTypeName);
    }

    public virtual void Update(T entity, string entityTypeName)
    {
        _applicationDbContext.Set<T>(entityTypeName).Update(entity);
    }


    protected virtual List<DbParameter> getParamForProc(string sc_name, string sp_name, List<DbParameter> parameters)
    {
        List<DbParameter> result = new List<DbParameter>();

        DbCommand command = _connection.CreateCommand();
        command.CommandText = "EXEC [dbo].[asGetProcedureParameters] @scName, @spName";
        command.Parameters.Add(new SqlParameter("@scName", sc_name));
        command.Parameters.Add(new SqlParameter("@spName", sp_name));

        DbDataReader dbDataReader = command.ExecuteReader();
        DataTable table = new DataTable();
        table.Load(dbDataReader);

        foreach (DataRow parameter in table.Rows)
        {
            ParameterDirection direction = parameter["PARAMETER_MODE"].ToString() == "IN" ? ParameterDirection.Input : ParameterDirection.InputOutput;
            string parameter_name = parameter["PARAMETER_NAME"].ToString() ?? "";
            string data_type = parameter["DATA_TYPE"].ToString() ?? "";

            DbParameter? cParam = parameters.Find(p => p.ParameterName.ToLower() == parameter_name.ToLower());
            DbParameter param = new SqlParameter();
            param.Direction = direction;
            if (cParam is not null)
            {
                param.ParameterName = cParam.ParameterName;
                param.Value = cParam.Value;
            }
            else
            {
                Type type = typeof(string);
                switch (data_type)
                {
                    case "time":
                        type = typeof(TimeOnly);
                        break;
                    case "date":
                    case "datetime2":
                    case "datetimeoffset":
                    case "smalldatetime":
                    case "datetime":
                        type = typeof(DateTime);
                        break;
                    case "text":
                    case "ntext":
                    case "varchar":
                    case "char":
                    case "nvarchar":
                    case "nchar":
                        type = typeof(string);
                        break;
                    case "tinyint":
                    case "smallint":
                    case "int":
                    case "bigint":
                        type = typeof(int);
                        break;
                    case "money":
                    case "float":
                    case "decimal":
                    case "numeric":
                    case "smallmoney":
                        type = typeof(Decimal);
                        break;
                    case "bit":
                        type = typeof(System.Boolean);
                        break;
                }

                param.ParameterName = parameter_name;
                param.Value = defaultValues[type];
            }
            result.Add(param);
        }

        return result;
    }
    protected virtual void BeforeExecute() { }
    protected virtual void AfterExecute() { }
}

public class BaseEFRepoException : Exception
{
    public BaseEFRepoException() : base() { }
    public BaseEFRepoException(string? s) : base(s) { }

    public BaseEFRepoException(string? message, Exception? innerException) : base(message, innerException) { }
}

public class SqlExpressionVisitor : ExpressionVisitor
{
    private readonly StringBuilder _sb = new();
    private List<string> fields = new List<string>();

    public string Translate(Expression expression)
    {
        Visit(expression);
        return _sb.ToString();
    }

    public List<string> GetFields()
    {
        return fields; 
    }

    protected override Expression VisitBinary(BinaryExpression node)
    {
        _sb.Append("(");
        Visit(node.Left);

        switch (node.NodeType)
        {
            case ExpressionType.Equal: _sb.Append(" = "); break;
            case ExpressionType.NotEqual: _sb.Append(" <> "); break;
            case ExpressionType.AndAlso: _sb.Append(" AND "); break;
            case ExpressionType.OrElse: _sb.Append(" OR "); break;
            case ExpressionType.GreaterThan: _sb.Append(" > "); break;
            case ExpressionType.LessThan: _sb.Append(" < "); break;
        }

        Visit(node.Right);
        _sb.Append(")");
        return node;
    }

    protected override Expression VisitMember(MemberExpression node)
    {
        _sb.Append(node.Member.Name);
        fields.Add(node.Member.Name.ToLower());
        return node;
    }

    protected override Expression VisitConstant(ConstantExpression node)
    {
        if (node.Type == typeof(string))
            _sb.Append($"'{node.Value}'");
        else if (node.Type == typeof(System.Boolean))
        {
            bool boolVal = (bool)(node.Value ?? false);
            _sb.Append(boolVal == true ? "1 = 1" : "1 = 0");
        }
        else
            _sb.Append(node.Value);
        return node;
    }

    protected override Expression VisitMethodCall(MethodCallExpression node)
    {
        if (node.Method.Name == "Contains")
        {
            Visit(node.Object);
            _sb.Append(" LIKE ");
            var arg = (ConstantExpression)node.Arguments[0];
            _sb.Append($"'%{arg.Value}%'");
        }
        return node;
    }
}