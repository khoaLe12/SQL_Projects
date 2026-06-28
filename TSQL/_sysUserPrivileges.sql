IF OBJECT_ID('dbo.sysUserPrivilege', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysUserPrivilege] (
		id Nvarchar(50) NOT NULL DEFAULT '',
		[user_id] Nvarchar(50) NOT NULL DEFAULT '',
		action_code Nvarchar(20) NOT NULL DEFAULT '',
		scope Nvarchar(20) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysUserPrivileges PRIMARY KEY (id)
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysUserPrivilege', 'U') AND name = 'Idx_sysUserPrivilege_user_id')
		CREATE NONCLUSTERED INDEX Idx_sysUserPrivilege_user_id ON sysUserPrivilege([user_id])
END

IF NOT EXISTS (SELECT * FROM sysUserPrivilege WHERE scope = 'Address')
BEGIN
	INSERT INTO sysUserPrivilege(id, [user_id], action_code, scope)
	VALUES (CAST(NEWID() AS Nvarchar(50)), 'af5125f8-6c75-4bb9-acbe-a7b3a6829e35', 'CREATE', 'Address'),
		(CAST(NEWID() AS Nvarchar(50)), 'af5125f8-6c75-4bb9-acbe-a7b3a6829e35', 'UPDATE', 'Address'),
		(CAST(NEWID() AS Nvarchar(50)), 'af5125f8-6c75-4bb9-acbe-a7b3a6829e35', 'DELETE', 'Address'),
		(CAST(NEWID() AS Nvarchar(50)), 'af5125f8-6c75-4bb9-acbe-a7b3a6829e35', 'GET', 'Address'),
		(CAST(NEWID() AS Nvarchar(50)), 'af5125f8-6c75-4bb9-acbe-a7b3a6829e35', 'GETALL', 'Address')
END