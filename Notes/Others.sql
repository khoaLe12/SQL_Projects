

-- Example of working with binary data
CREATE TABLE T (
	Col1 Int IDENTITY(1,1) PRIMARY KEY,
	Col2 Varbinary(100)
);
GO

-- Insert sample binary data
INSERT INTO T VALUES(0x1234567890);
GO

-- Retrieve binary data
SELECT Col2 FROM T;
GO

-- Create XML document that has base64 encoded binary data, then select the encoded string
SELECT (
	SELECT *
	FROM T
	FOR XML AUTO, TYPE, BINARY BASE64
).value('(/T[1]/@Col2)[1]', 'varchar(MAX)');
GO

-- Convert the base64 encoded string to binary data
DECLARE @x varchar(MAX) = 'EjRWeJA=';
SELECT CAST('<binary>' + @x + '</binary>' AS XML).value('.', 'varbinary(MAX)');
GO