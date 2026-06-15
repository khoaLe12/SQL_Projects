IF OBJECT_ID('dbo.sysCDCDataChanges') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysCDCDataChanges] (
		id Int NOT NULL IDENTITY(1,1) PRIMARY KEY,
		data_table Nvarchar(255) NOT NULL DEFAULT '',
		data_key Nvarchar(255) NOT NULL DEFAULT '',
		data_original Nvarchar(MAX) NOT NULL DEFAULT '',
		data_target Nvarchar(MAX) NOT NULL DEFAULT '',
		data_change Nvarchar(MAX) NOT NULL DEFAULT '',
		action_content Nvarchar(200) NOT NULL DEFAULT '',
		action_code Nvarchar(20) NOT NULL DEFAULT '',
		lsn Binary(10) NOT NULL DEFAULT 0x0
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysCDCDataChanges') AND name = 'Idx_sysCDCDataChanges_dataTable_dataKey')
		CREATE NONCLUSTERED INDEX Idx_sysCDCDataChanges_dataTable_dataKey ON [dbo].[sysCDCDataChanges](data_table, data_key)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysCDCDataChanges') AND name = 'Idx_sysCDCDataChanges_dataTable_lsn')
		CREATE NONCLUSTERED INDEX Idx_sysCDCDataChanges_dataTable_lsn ON [dbo].[sysCDCDataChanges](data_table, lsn)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysCDCDataChanges') AND name = 'Idx_sysCDCDataChanges_dataTable_actionCode')
		CREATE NONCLUSTERED INDEX Idx_sysCDCDataChanges_dataTable_actionCode ON [dbo].[sysCDCDataChanges](data_table, action_code)
END