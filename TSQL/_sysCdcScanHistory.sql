IF OBJECT_ID('dbo.sysCdcScanHistory') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysCdcScanHistory] (
		id Int NOT NULL IDENTITY(1,1) PRIMARY KEY,
		lsn_start Binary(10) NOT NULL DEFAULT 0,
		lsn_end Binary(10) NOT NULL DEFAULT 0,
		[timestamp] Smalldatetime NOT NULL DEFAULT '',
		duration_sec Decimal(6,4) NOT NULL DEFAULT 0,
		read_count Int NOT NULL DEFAULT 0
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysCdcScanHistory') AND name = 'Idx_sysCdcScanHistory_LsnEnd')
		CREATE NONCLUSTERED INDEX Idx_sysCdcScanHistory_LsnEnd ON dbo.sysCdcScanHistory(lsn_end)
END