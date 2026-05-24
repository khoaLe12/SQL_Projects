CREATE OR ALTER PROCEDURE [dbo].[asAddressGet]
	@pAddressID int = NULL,
	@pAddressLine1 Nvarchar(60) = '',
	@pAddressLine2 Nvarchar(60) = '',
	@pCity Nvarchar(30) = '',
	@pStateProvinceCode Nvarchar(3) = ''
AS
	IF @pAddressID IS NULL
		SET @pAddressID = 0

	SELECT
		a.AddressID,
		a.AddressLine1,
		a.AddressLine2,
		a.City,
		a.PostalCode,
		a.StateProvinceID,
		ISNULL(s.StateProvinceCode, '') AS StateProvinceCode,
		ISNULL(s.CountryRegionCode, '') AS CountryRegionCode,
		ISNULL(s.Name, '') AS Name
	FROM [Person].[Address] a
	LEFT JOIN [Person].[StateProvince] s ON s.StateProvinceID = a.StateProvinceID AND (@pStateProvinceCode = '' OR s.StateProvinceCode LIKE @pStateProvinceCode + '%')
	WHERE (@pAddressID = 0 OR AddressID = @pAddressID)
		AND (@pAddressLine1 = '' OR AddressLine1 LIKE @pAddressLine1 + '%')
		AND (@pAddressLine2 = '' OR AddressLine2 LIKE @pAddressLine2 + '%')
		AND (@pCity = '' OR City LIKE @pCity + '%')