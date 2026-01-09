-- quick

select
	concat(REPLICATE('0', 4), REPLICATE('1', 4)),
	REVERSE('Hello World')




-- 1. SKIP 0 AND TAKE 20
select 
	JobTitle, HireDate
from HumanResources.Employee
order by HireDate DESC
offset 0 rows
fetch next 20 rows only




-- 2. ESCAPE CHARACTERS
select *
from production.ProductPhoto
where LargePhotoFileName like '%greena_%' ESCAPE 'a'




-- 3. TEXT SEARCH:
-- _ ANY CHARACTER
-- [a-Z]: ANY CHARACTER from a to Z
-- [^a-Z]: NOT ANY CHARACTER from a to Z
select 
	name
from Production.Product
where name like 'chain_[a-Z][^a-Z]%'




-- 4. CONCAT, || ->  NỐI CHUỖI
-- CONCAT_WS -> NỐI CHUỖI VỚI SEPERATOR ','
select 
	concat(p.FirstName, ' ', p.LastName) || CHAR(13) || CHAR(10) || a.EmailAddress,
	concat_ws(', ', p.FirstName, p.LastName, CHAR(13) || CHAR(10), a.EmailAddress)
from Person.Person p 
inner join Person.EmailAddress a on a.BusinessEntityID = p.BusinessEntityID



-- 5. TRIM, LTRIM, RTRIM
-- TRIM CAN BE USED TO REMOVE (SPACE/SPECIFIC CHARACTERS) BETWEEN STRING
-- 67:
select 
	ProductNumber,
	substring(ProductNumber, 3, len(ProductNumber)) as _substring,
	LTRIM(ProductNumber, 'HN') as _ltrim -- REMOVE LEFT SUBSTRING 'HN'
from Production.Product
where ProductNumber like 'HN%'



-- 6. REMOVE SPACES INSIDE TEXT
declare @r nvarchar(max) = ''
declare @s Nvarchar(max) = 'text then five spaces     after space     test  aaaa tetst'
declare @i int = charindex('  ', @s)
while @i <> 0
begin
	set @r = @r + left(@s, @i - 1)
	set @s = ' ' + ltrim(SUBSTRING(@s, @i))
	set @i = charindex('  ', @s)
end
select @r + @s



-- 7. CASE-SENSITIVE TEXT SEARCH
select
	productnumber,
	name
from Production.Product
where name COLLATE Latin1_General_CS_AS like '%[SML]'



-- 8. AGGREGATE FUNCTION VAR, VARP
-- var is used to calculate sample variance
-- varp is used to calculate population variance



-- 9. GROUP OPERATOR (ROLLUP, CUBE) (Notes: ROLLUP is a subset of CUBE | ROLLUP ⊂ CUBE)
-- ROLLUP: produce hierarchical subtotals which starts from the rightmost columns and rolls upward
-- SETS: detail of rightmost -> subtotal while rolling upward -> grand total
------------------------------------------
-- CUBE: produces all possible combinations of subtotals
-- SETS: detail of each individual column -> subtotal of every possible combination of columns -> grand total
------------------------------------------
-- GROUPING SET: unions together the result of each specify grouping set
------------------------------------------
-- GROUPING FUNCTION: indicates whether a specified columns expression in a GROUP BY list is aggregated or not
-- 1 for aggregated and 0 for not aggregated
-- GROUPING is used to distinguish the null values that are returned by ROLLUP, CUBE or GROUPING SETS from standard null values
-- If at a row: GROUPING value is 1 and value of aggregated column is NULL -> that column is being aggregated (NULL means all values of that column are being aggregated)
-- If at a row: GROUPING value is 0 and value of aggregated column is null -> that column actually have NULL value (that NULL value is being aggregated)
;
SELECT locationid, shelf, SUM(quantity) AS TotalQuantity, 
	GROUPING(locationid) AS [Grouping_locationid], -- GROUPING does not work with simple group by
	GROUPING(shelf) AS [Grouping_shelf]
FROM production.productinventory
GROUP BY locationid, shelf
;
SELECT locationid, shelf, SUM(quantity) AS TotalQuantity, 
	GROUPING(locationid) AS [Grouping_locationid],
	GROUPING(shelf) AS [Grouping_shelf]
FROM production.productinventory
GROUP BY ROLLUP (locationid, shelf)
;
SELECT locationid, shelf, SUM(quantity) AS TotalQuantity, GROUPING(Quantity) AS [Grouping]
FROM production.productinventory
GROUP BY CUBE (locationid, shelf)
;
SELECT locationid, shelf, SUM(quantity) AS TotalQuantity, GROUPING(Quantity) AS [Grouping]
FROM production.productinventory
GROUP BY GROUPING SETS (CUBE(locationid, shelf), ROLLUP (locationid, shelf), (locationid), (shelf), ())



-- 10: how to convert a current datetime to the beginning and the end of the date
DECLARE @current_date Smalldatetime = GETDATE();
select
	@current_date as [current_date],
	CAST(CAST(@current_date AS date) AS smalldatetime) as beginning_date,
	DATEADD(MINUTE, -1, DATEADD(DAY, 1, DATEDIFF(DAY, 0, @current_date))) as end_date