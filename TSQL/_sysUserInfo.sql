IF OBJECT_ID('dbo.sysUserInfo', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysUserInfo] (
		id Nvarchar(50) NOT NULL DEFAULT '',
		username Nvarchar(20) NOT NULL DEFAULT '',
		password Nvarchar(100) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysUserInfo PRIMARY KEY (id)
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysUserInfo', 'U') AND name = 'Idx_sysUserInfo_username_password')
		CREATE UNIQUE NONCLUSTERED INDEX Idx_sysUserInfo_username_password ON sysUserInfo(username, password)
END

