CREATE OR ALTER PROCEDURE [dbo].[asAddressDel]
	@pAddressID Int,
	@pRet Int OUTPUT
AS
	DELETE FROM Person.Address
	WHERE AddressID = @pAddressID

	SET @pRet = @@ERROR