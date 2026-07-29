using API.Models.SysEntities;
using Dapper;

namespace API.DapperImplementation.Base.Repository;

public interface ISystemRepository : IBaseRepository
{
    SysDictionary? GetDictionaryInformation(string code_name, string schema_name, string table_name);
    sysDAOInfo? GetDAOInformation(string code_name);
}
public class SystemRepository : BaseRepository, ISystemRepository
{
    public SystemRepository(AdventureWorks2025Connection connection) : base(connection) { }


    // Hard code system table query in purpose of showing all available system tables
    public SysDictionary? GetDictionaryInformation(string code_name, string schema_name, string table_name)
    {
        string sp_name = "asSysDictionaryGet";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("code_name", code_name);
        parameters.Add("schema_name", schema_name);
        parameters.Add("table_name", table_name);
        var result = QuerySingleSystemTable<SysDictionary>(sp_name, parameters);
        return result;
    }

    public sysDAOInfo? GetDAOInformation(string code_name)
    {
        string sp_name = "asSysDAOInfoGet";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("code_name", code_name);
        var result = QuerySingleSystemTable<sysDAOInfo>(sp_name, parameters);
        return result;
    }
}
