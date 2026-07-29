using API.DapperImplementation.Base;
using API.DapperImplementation.Base.Repository;
using API.Models.SysEntities;
using Dapper;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Text.Json;

namespace API.DapperImplementation.Repositories;

public interface IHomeRepository : IBaseRepository
{
    bool Register(string id, string username, string password);
    (sysUserInfo?, List<sysUserPrivilege>) Login(string username, string password);
}

public class HomeRepository : BaseRepository, IHomeRepository
{

    public HomeRepository(AdventureWorks2025Connection connection) : base(connection)
    {
    }

    public bool Register(string id, string username, string password)
    {
        string sp_name = "asRegisterAccount";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("id", id);
        parameters.Add("user_name", username);
        parameters.Add("password", password);
        ExecuteNonQuery("dbo", sp_name, ref parameters);
        int resultInt = parameters.Get<Int32>("@pRet");
        return resultInt == 0;
    }

    public (sysUserInfo?, List<sysUserPrivilege>) Login(string username, string password)
    {
        string sp_name = "asLoginAccount";
        DynamicParameters parameters = new DynamicParameters();
        parameters.Add("user_name", username);
        parameters.Add("password", password);
        List<List<dynamic>> result = ExecuteMultiQuery("dbo", sp_name, ref parameters);

        sysUserInfo? userInfo = null;
        List<sysUserPrivilege> sysUserPrivileges = new List<sysUserPrivilege>();

        if (result.Count > 0)
        {
            var users = result[0];
            var json = JsonConvert.SerializeObject(users.FirstOrDefault());
            userInfo = JsonConvert.DeserializeObject<sysUserInfo>(json);
        }
        if (result.Count > 0)
        {
            var priviledges = result[1];
            var json = JsonConvert.SerializeObject(priviledges);
            sysUserPrivileges = JsonConvert.DeserializeObject<List<sysUserPrivilege>>(json) ?? new List<sysUserPrivilege>();
        }

        return (userInfo, sysUserPrivileges);
    }
}
