IF OBJECT_ID('sysBackupHistory', 'U') IS NULL
BEGIN
	CREATE TABLE sysBackupHistory (
		id Int PRIMARY KEY IDENTITY(1, 1) NOT NULL,

	)
END