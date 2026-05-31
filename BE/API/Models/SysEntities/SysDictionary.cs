using SQLAgent.Models.BaseModel;

namespace SQLAgent.Models.SysEntities;

public class SysDictionary : SysEntity
{
    public string code_name { get; set; }
    public int code_length { get; set; }
    public string table_name { get; set; }
    public string schema_name { get; set; }
    public string description { get; set; }

    public SysDictionary(string id, string code_name, int code_length, string table_name, string schema_name, string description) : base(id)
    {
        this.code_name = code_name;
        this.code_length = code_length;
        this.table_name = table_name;
        this.schema_name = schema_name;
        this.description = description;
    }
}
