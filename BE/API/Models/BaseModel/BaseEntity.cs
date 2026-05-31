namespace SQLAgent.Models.BaseModel;

public class BaseEntity
{
    public object Clone()
    {
        return this.MemberwiseClone();
    }
}
