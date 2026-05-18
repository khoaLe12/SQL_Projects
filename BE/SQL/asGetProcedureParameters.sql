CREATE OR ALTER PROCEDURE [dbo].[asGetProcedureParameters]
	@scName Nvarchar(10) = 'dbo',
	@spName Nvarchar(100) = 'asAddressGet'
AS
	SELECT 
		p.name AS PARAMETER_NAME,
		t.name AS DATA_TYPE,
		CASE p.is_output 
			WHEN 1 THEN 'OUT'
			ELSE 'IN'
		END AS PARAMETER_MODE
	FROM sys.procedures sp
	LEFT JOIN sys.parameters p ON p.object_id = sp.object_id
	LEFT JOIN sys.types t ON t.system_type_id = p.system_type_id AND t.user_type_id = p.user_type_id
	WHERE sp.schema_id = SCHEMA_ID(@scName)
		AND sp.name = @spName
		AND sp.type = 'P'