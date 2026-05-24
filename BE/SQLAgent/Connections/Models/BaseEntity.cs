namespace SQLAgent.Connections.Models;

public class BaseEntity
{
    public object Clone()
    {
        return this.MemberwiseClone();
    }
}
