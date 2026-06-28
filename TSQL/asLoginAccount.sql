CREATE OR ALTER PROCEDURE [dbo].[asLoginAccount]
	@pUser_name Nvarchar(20),
	@pPassword Nvarchar(100)
AS
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#temp') IS NOT NULL
		DROP TABLE #temp

	SELECT * 
	INTO #temp
	FROM sysUserInfo 
	WHERE username = @pUser_name 
		AND password = @pPassword

	SELECT * FROM #temp

	SELECT * 
	FROM sysUserPrivilege
	WHERE [user_id] = (SELECT TOP 1 id FROM #temp)

	IF OBJECT_ID('tempdb..#temp') IS NOT NULL
		DROP TABLE #temp

	SET NOCOUNT OFF;
