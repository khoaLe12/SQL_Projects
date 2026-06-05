using API.Models.BaseModel;

namespace API.Models.SysEntities;

public class sysDAOInfo : SysEntity
{
    public string code_name { get; set; }
    public string sp_schema { get; set; }
    public string sp_get { get; set; }
    public string sp_ins { get; set; }
    public string sp_upd { get; set; }
    public string sp_del { get; set; }

    public sysDAOInfo(string id, string code_name, string sp_schema, string sp_get, string sp_ins, string sp_upd, string sp_del) : base(id)
    {
        this.code_name = code_name;
        this.sp_schema = sp_schema;
        this.sp_get = sp_get;
        this.sp_ins = sp_ins;
        this.sp_upd = sp_upd;
        this.sp_del = sp_del;
    }
}
