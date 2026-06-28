namespace API.Models.SysEntities;

public class sysUserInfo
{
    public string Id { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }

    public sysUserInfo(string id, string username, string password)
    {
        this.Id = id;
        this.Username = username;
        this.Password = password;
    }
}
