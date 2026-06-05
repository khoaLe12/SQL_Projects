namespace API.Models.SysEntities;

public class sysUserPrivileges
{
    public string id { get; set; }
    public string user_id { get; set; }
    public string action_code { get; set; }
    public string scope { get; set; }

    public sysUserPrivileges(string id, string user_id, string action_code, string scope)
    {
        this.id = id;
        this.user_id = user_id;
        this.action_code = action_code;
        this.scope = scope;
    }
}
