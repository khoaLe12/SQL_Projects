IF OBJECT_ID('dbo.sysHistory') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysHistory] (
		id Int NOT NULL IDENTITY (1, 1) PRIMARY KEY,
		data_table Nvarchar(255) NOT NULL DEFAULT '',
		data_key Nvarchar(500) NOT NULL DEFAULT '',
		data_original Nvarchar(MAX) NOT NULL DEFAULT '',
		data_target Nvarchar(MAX) NOT NULL DEFAULT '',
		data_change Nvarchar(MAX) NOT NULL DEFAULT '',
		action_content Nvarchar(200) NOT NULL DEFAULT '',
		action_code Nvarchar(20) NOT NULL DEFAULT '',
		[timestamp] Smalldatetime NOT NULL DEFAULT '',
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysHistory') AND name = 'Idx_sysHistory_dataTable_dataKey')
		CREATE NONCLUSTERED INDEX Idx_sysHistory_dataTable_dataKey ON [dbo].[sysHistory](data_table, data_key)
END