CREATE OR ALTER PROCEDURE [dbo].[asRegisterAccount]
	@pId Nvarchar(50),
	@pUser_name Nvarchar(20),
	@pPassword Nvarchar(100),
	@pRet Int OUTPUT
AS
	INSERT INTO sysUserInfo(id, username, password)
	VALUES(@pId, @pUser_name, @pPassword)

	SET @pRet = @@ERROR