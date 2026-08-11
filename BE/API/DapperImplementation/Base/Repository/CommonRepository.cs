using Dapper;

namespace API.DapperImplementation.Base.Repository;

public interface ICommonRepository : IBaseRepository
{
    dynamic? ExecuteQuerySingle(string scName, string spName, ref DynamicParameters dynamicParameters);
    void ExecuteNonQuery(string scName, string spName, ref DynamicParameters dynamicParameters);
}

public class CommonRepository : BaseRepository, ICommonRepository
{
    public CommonRepository(AdventureWorks2025Connection connection) : base(connection)
    {
    }

    public new dynamic? ExecuteQuerySingle(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        return base.ExecuteQuerySingle(scName, spName, ref dynamicParameters);
    }

    public new void ExecuteNonQuery(string scName, string spName, ref DynamicParameters dynamicParameters)
    {
        base.ExecuteNonQuery(scName, spName, ref dynamicParameters);
    }
}
