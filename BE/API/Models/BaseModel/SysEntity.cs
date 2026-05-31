namespace SQLAgent.Models.BaseModel;

public class SysEntity
{
    public string id { get; set; }

    public SysEntity(string id)
    {
        this.id = id;
    }

    public object Clone()
    {
        return this.MemberwiseClone();
    }
}
