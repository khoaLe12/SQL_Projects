CREATE OR ALTER PROCEDURE [dbo].[asSysDAOInfoGet]
	@pCode_name Nvarchar(20)
AS
	IF @pCode_name IS NULL
		SET @pCode_name = ''

	SELECT * FROM sysDAOInfo
	WHERE @pCode_name = '' OR code_name = @pCode_name