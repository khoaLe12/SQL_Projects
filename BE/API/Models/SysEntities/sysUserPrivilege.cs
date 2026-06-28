namespace API.Models.SysEntities;

public class sysUserPrivilege
{
    public string Id { get; set; }
    public string User_id { get; set; }
    public string Action_code { get; set; }
    public string Scope { get; set; }

    public sysUserPrivilege(string id, string user_id, string scope, string action_code)
    {
        this.Id = id;
        this.User_id = user_id;
        this.Action_code = action_code;
        this.Scope = scope;
    }
}
