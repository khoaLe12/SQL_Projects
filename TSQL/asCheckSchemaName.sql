CREATE OR ALTER PROCEDURE [dbo].[asCheckSchemaName]
	@pSchema_name Nvarchar(128),
	@pRet Int OUTPUT
AS
	SET @pRet = 0
	IF NOT EXISTS(SELECT * FROM sys.schemas WHERE name = @pSchema_name)
		SET @pRet = 1