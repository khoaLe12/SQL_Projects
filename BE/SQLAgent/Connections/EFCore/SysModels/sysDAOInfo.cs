namespace SQLAgent.Connections.EFCore.SysModels
{
    public class sysDAOInfo
    {
        public string id { get; set; }
        public string schema_name { get; set; }
        public string table_name { get; set; }
        public string sp_get { get; set; }
        public string sp_ins { get; set; }
        public string sp_upd { get; set; }
        public string sp_del { get; set; }
    }
}
