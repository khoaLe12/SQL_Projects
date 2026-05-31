using Dapper;
using System.Reflection;

namespace SQLAgent.Models.BaseModel;

public class EntityKey
{
    public void AttachKeys(ref DynamicParameters parameters)
    {
        PropertyInfo[] props = this.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
        foreach (PropertyInfo prop in props)
        {
            string name = prop.Name;
            object value = prop.GetValue(this) ?? "";
            parameters.Add(name, value);
        }
    }
}
