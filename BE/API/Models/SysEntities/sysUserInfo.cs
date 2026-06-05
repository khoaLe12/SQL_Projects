namespace API.Models.SysEntities;

public class sysUserInfo
{
    public string id { get; set; }
    public string username { get; set; }
    public string password { get; set; }

    public sysUserInfo(string id, string username, string password)
    {
        this.id = id;
        this.username = username;
        this.password = password;
    }
}
