namespace SQLAgent.Connections.EFCore.Data;

public class BaseEntity
{
    public object Clone()
    {
        return this.MemberwiseClone();
    }
}
