namespace SQLAgent.Connections.SysModels;

public class sysDAOInfo : SysEntity
{
    public string id { get; set; }
    public string table_schema { get; set; }
    public string table_name { get; set; }
    public string sp_schema { get; set; }
    public string sp_get { get; set; }
    public string sp_ins { get; set; }
    public string sp_upd { get; set; }
    public string sp_del { get; set; }
}
