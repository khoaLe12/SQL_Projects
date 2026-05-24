CREATE OR ALTER PROCEDURE [dbo].[asAddressUpd]
	@pAddressID Int,
	@pAddressLine1 Nvarchar(60),
	@pAddressLine2 Nvarchar(60),
	@pCity Nvarchar(30),
	@pStateProvinceID Int,
	@pPostalCode Nvarchar(15),
	@pRet Int OUTPUT
AS
	IF NOT EXISTS (SELECT * FROM Person.StateProvince WHERE StateProvinceID = @pStateProvinceID)
	BEGIN
		SET @pRet = 10001
		RETURN
	END

	UPDATE Person.Address
	SET AddressLine1 = @pAddressLine1,
		AddressLine2 = @pAddressLine2,
		City = @pCity,
		StateProvinceID = @pStateProvinceID,
		PostalCode = @pPostalCode
	WHERE AddressID = @pAddressID

	SET @pRet = @@ERROR