CREATE OR ALTER PROCEDURE [dbo].[asSysConfigurationGet]
	@pId Int
AS 
	IF @pId IS NULL
		SET @pId = 0

	SELECT 
		TOP 1 *
	FROM [dbo].[sysConfiguration]
	WHERE (@pId = 0 OR id = @pId)
	ORDER BY [default] DESC