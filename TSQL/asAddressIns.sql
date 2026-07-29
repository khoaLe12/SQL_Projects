CREATE OR ALTER PROCEDURE [dbo].[asAddressIns]
	@pAddressLine1 Nvarchar(60),
	@pAddressLine2 Nvarchar(60),
	@pCity Nvarchar(30),
	@pStateProvinceID Int,
	@pPostalCode Nvarchar(15),
	@pRet Int OUTPUT
AS
	IF NOT EXISTS (SELECT * FROM Person.StateProvince WHERE StateProvinceID = @pStateProvinceID)
	BEGIN
		SET @pRet = 10
		RETURN
	END

	IF EXISTS (
		SELECT * FROM 
		Person.Address 
		WHERE AddressLine1 = @pAddressLine1 
			AND AddressLine2 = @pAddressLine2
			AND City = @pCity
			AND StateProvinceID = @pStateProvinceID
			AND PostalCode = @pPostalCode
	)
	BEGIN
		SET @pRet = 2627
		RETURN
	END

	DECLARE @ids TABLE(AddressID Int);

	INSERT INTO Person.Address (
		AddressLine1, 
		AddressLine2, 
		City,
		StateProvinceID,
		PostalCode,
		SpatialLocation,
		rowguid,
		ModifiedDate
	)
	OUTPUT INSERTED.AddressID INTO @ids
	VALUES (
		@pAddressLine1,
		@pAddressLine2,
		@pCity,
		@pStateProvinceID,
		@pPostalCode,
		NULL,
		NEWID(),
		GETDATE()
	)

	SELECT TOP 1 AddressID FROM @ids

	SET @pRet = @@ERROR