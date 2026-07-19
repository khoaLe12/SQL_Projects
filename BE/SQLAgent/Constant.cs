using System;
using System.Collections.Generic;
using System.Text;

namespace SQLAgent;

public static class Constant
{
    public static class AgentProcedures
    {
        public const string CHANGE_DATA_CAPTURE = "asCDCScan";
        public const string FULL_BACKUP = "asFullBackup";
        public const string DIFFERENTIAL_BACKUP = "asDifferentialBackup";
        public const string LOG_BACKUP = "asLogBackup";
    }
}
