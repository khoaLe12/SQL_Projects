using API.Common;
using API.Constant;
using API.DapperImplementation.Base.Repository;
using Dapper;
using Newtonsoft.Json.Linq;

namespace API.SQLAgent;

public class SQLAgent : BackgroundService
{
    private readonly IServiceProvider Services;

    public SQLAgent(IServiceProvider services)
    {
        Services = services;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        int fullBackupInterval = 7;
        int differentialBackupInterval = 24;
        int logBackupInterval = 30;
        int cdcInterval = 5;

        JObject? lastFullBackup = null;
        JObject? lastDifferentialBackup = null;
        JObject? lastLogBackup = null;

        using (var scope = Services.CreateScope())
        {
            ICommonRepository commonRepository = scope.ServiceProvider.GetRequiredService<ICommonRepository>();

            DynamicParameters parameters = new DynamicParameters();
            JObject configuration = JObject.FromObject(commonRepository.ExecuteQuerySingle("dbo", Constant.Constant.SYSTEM_CONFIGURATION_GET, ref parameters));

            if (configuration != null)
            {
                if (configuration.TryGetValue("full_backup_interval", out JToken? fullBackupIntervalToken) && fullBackupIntervalToken != null && fullBackupIntervalToken.Type == JTokenType.Integer)
                {
                    fullBackupInterval = fullBackupIntervalToken.Value<int>();
                }
                if (configuration.TryGetValue("differential_backup_interval", out JToken? differentialBackupIntervalToken) && differentialBackupIntervalToken != null && differentialBackupIntervalToken.Type == JTokenType.Integer)
                {
                    differentialBackupInterval = differentialBackupIntervalToken.Value<int>();
                }
                if (configuration.TryGetValue("log_backup_interval", out JToken? logBackupIntervalToken) && logBackupIntervalToken != null && logBackupIntervalToken.Type == JTokenType.Integer)
                {
                    logBackupInterval = logBackupIntervalToken.Value<int>();
                }
                if (configuration.TryGetValue("cdc_interval", out JToken? cdcIntervalToken) && cdcIntervalToken != null && cdcIntervalToken.Type == JTokenType.Integer)
                {
                    cdcInterval = cdcIntervalToken.Value<int>();
                }
            }

            IBackupRepository backupRepository = scope.ServiceProvider.GetRequiredService<IBackupRepository>();

            parameters = new DynamicParameters();

            dynamic? lfb = backupRepository.ExecuteQuerySingle("dbo", Constant.Constant.FULL_BACKUP_GET_LAST, ref parameters);
            if (lfb != null) lastFullBackup = JObject.FromObject(lfb);

            dynamic? ldb = backupRepository.ExecuteQuerySingle("dbo", Constant.Constant.DIFFERENTIAL_BACKUP_GET_LAST, ref parameters);
            if (ldb != null) lastDifferentialBackup = JObject.FromObject(ldb);

            dynamic? llb = backupRepository.ExecuteQuerySingle("dbo", Constant.Constant.LOG_BACKUP_GET_LAST, ref parameters);
            if (llb != null) lastLogBackup = JObject.FromObject(llb);
        }


        Task fullBackupTask = Task.Run(async () =>
        {
            if (lastFullBackup != null)
            {
                if (lastFullBackup.TryGetValue("timestamp", out JToken? timestampToken) && timestampToken.Type == JTokenType.Date)
                {
                    DateTime timestamp = timestampToken.Value<DateTime>();
                    DateTime estimatedTime = timestamp.AddDays(fullBackupInterval);
                    DateTime now = DateTime.Now;
                    if (estimatedTime > now)
                    {
                        TimeSpan different = estimatedTime - now;
                        await Task.Delay(different, stoppingToken);
                        return;
                    }
                }
            }
            await ExecuteFullBackup(stoppingToken, fullBackupInterval);
        });

        Task differentialBackupTask = Task.Run(async () =>
        {
            if (lastDifferentialBackup != null)
            {
                if (lastDifferentialBackup.TryGetValue("timestamp", out JToken? timestampToken) && timestampToken.Type == JTokenType.Date)
                {
                    DateTime timestamp = timestampToken.Value<DateTime>();
                    DateTime estimatedTime = timestamp.AddHours(differentialBackupInterval);
                    DateTime now = DateTime.Now;
                    if (estimatedTime > now)
                    {
                        TimeSpan different = estimatedTime - now;
                        await Task.Delay(different, stoppingToken);
                    }
                }
            }
            await ExecuteDifferentialBackup(stoppingToken, differentialBackupInterval);
        });

        Task logBackupTask = Task.Run(async () =>
        {
            if (lastLogBackup != null)
            {
                if (lastLogBackup.TryGetValue("timestamp", out JToken? timestampToken) && timestampToken.Type == JTokenType.Date)
                {
                    DateTime timestamp = timestampToken.Value<DateTime>();
                    DateTime estimatedTime = timestamp.AddMinutes(logBackupInterval);
                    DateTime now = DateTime.Now;
                    if (estimatedTime > now)
                    {
                        TimeSpan different = estimatedTime - now;
                        await Task.Delay(different, stoppingToken);
                    }
                }
            }
            await ExecuteLogBackup(stoppingToken, logBackupInterval);
        });

        Task cdcTask = Task.Run(async () => await ExecuteCDC(stoppingToken, cdcInterval));


        return Task.WhenAll(fullBackupTask, differentialBackupTask, logBackupTask, cdcTask);
    }

    private async Task ExecuteFullBackup(CancellationToken token, int interval = 7)
    {
        try
        {
            using (PeriodicTimer timer = new PeriodicTimer(TimeSpan.FromDays(interval)))
            {
                while (await timer.WaitForNextTickAsync(token))
                {
                    using (var scope = Services.CreateScope())
                    {
                        IBackupRepository backupRepository = scope.ServiceProvider.GetRequiredService<IBackupRepository>();
                        DynamicParameters parameters = new DynamicParameters();
                        parameters.Add("db_name", Constant.Constant.DB_NAME);
                        backupRepository.ExecuteNonQuery("dbo", Constant.Constant.FULL_BACKUP, ref parameters);
                        int resultInt = parameters.Get<int>("@pRet");
                        int recoveryId = parameters.Get<int>("@pRecovery_id");
                        if (resultInt != 0)
                        {
                            Utilities.AgentLog($"Full backup {recoveryId} failed, {resultInt}.");
                        }
                    }
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Hosted service is stopping, ignore this exception
        }
    }   

    private async Task ExecuteDifferentialBackup(CancellationToken token, int interval = 24)
    {
        try
        {
            using (PeriodicTimer timer = new PeriodicTimer(TimeSpan.FromHours(interval)))
            {
                while (await timer.WaitForNextTickAsync(token))
                {
                    using (var scope = Services.CreateScope())
                    {
                        IBackupRepository backupRepository = scope.ServiceProvider.GetRequiredService<IBackupRepository>();
                        DynamicParameters parameters = new DynamicParameters();
                        parameters.Add("db_name", Constant.Constant.DB_NAME);
                        backupRepository.ExecuteNonQuery("dbo", Constant.Constant.DIFFERENTIAL_BACKUP, ref parameters);
                        int resultInt = parameters.Get<int>("@pRet");
                        int recoveryId = parameters.Get<int>("@pRecovery_id");
                        if (resultInt != 0)
                        {
                            Utilities.AgentLog($"Differential backup {recoveryId} failed, {resultInt}.");
                        }
                    }
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Hosted service is stopping, ignore this exception
        }
    }

    private async Task ExecuteLogBackup(CancellationToken token, int interval = 30)
    {
        try
        {
            using (PeriodicTimer timer = new PeriodicTimer(TimeSpan.FromMinutes(5)))
            {
                while (await timer.WaitForNextTickAsync(token))
                {
                    using (var scope = Services.CreateScope())
                    {
                        IBackupRepository backupRepository = scope.ServiceProvider.GetRequiredService<IBackupRepository>();
                        DynamicParameters parameters = new DynamicParameters();
                        parameters.Add("db_name", Constant.Constant.DB_NAME);
                        backupRepository.ExecuteNonQuery("dbo", Constant.Constant.LOG_BACKUP, ref parameters);
                        int resultInt = parameters.Get<int>("@pRet");
                        int recoveryId = parameters.Get<int>("@pRecovery_id");
                        if (resultInt != 0)
                        {
                            Utilities.AgentLog($"Log backup {recoveryId} failed, {resultInt}.");
                        }
                    }
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Hosted service is stopping, ignore this exception
        }
    }

    private async Task ExecuteCDC(CancellationToken token, int interval = 5)
    {
        try
        {
            using (PeriodicTimer timer = new PeriodicTimer(TimeSpan.FromMinutes(interval)))
            {
                while (await timer.WaitForNextTickAsync(token))
                {
                    using (var scope = Services.CreateScope())
                    {
                        ICommonRepository commonRepository = scope.ServiceProvider.GetRequiredService<ICommonRepository>();
                        DynamicParameters parameters = new DynamicParameters();
                        commonRepository.ExecuteNonQuery("dbo", Constant.Constant.CHANGE_DATA_CAPTURE, ref parameters);
                        int resultInt = parameters.Get<int>("@pRet");
                        if (resultInt != 0)
                        {
                            Utilities.AgentLog($"CDC Scan failed, {resultInt}.");
                        }
                    }
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Hosted service is stopping, ignore this exception
        }
    }
}
