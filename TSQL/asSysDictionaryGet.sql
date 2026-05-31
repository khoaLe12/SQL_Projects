CREATE OR ALTER PROCEDURE [dbo].[asSysDictionaryGet]
	@pCode_name Nvarchar(20),
	@pSchema_name Nvarchar(10),
	@pTable_name Nvarchar(50)
AS
	IF @pCode_name IS NULL
		SET @pCode_name = ''
	IF @pSchema_name IS NULL
		SET @pSchema_name = ''
	IF @pTable_name IS NULL
		SET @pTable_name = ''

	SELECT * FROM sysDictionary
	WHERE (@pCode_name = '' OR code_name = @pCode_name)
		AND (@pSchema_name = '' OR schema_name = @pSchema_name)
		AND (@pTable_name = '' OR table_name = @pTable_name)