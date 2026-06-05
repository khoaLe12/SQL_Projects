IF OBJECT_ID('sysUserPrivileges', 'U') IS NOT NULL
BEGIN
	CREATE TABLE sysUserPrivileges (
		id Nvarchar(50) NOT NULL DEFAULT '',
		[user_id] Nvarchar(50) NOT NULL DEFAULT '',
		action_code Nvarchar(20) NOT NULL DEFAULT '',
		scope Nvarchar(20) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysUserPrivileges PRIMARY KEY (id)
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysUserPrivileges', 'U') AND name = 'Idx_sysUserPrivileges_user_id')
		CREATE NONCLUSTERED INDEX Idx_sysUserPrivileges_user_id ON sysUserPrivileges([user_id])
END

