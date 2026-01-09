-- hierarchyid data type represent the level of nodes inside a tree-like hierarchy
-- The value is stored as binary/hexadecimal -> to view its path use ToString() method
-- 1
SELECT 
	OrganizationLevel, 
	OrganizationNode AS orgNode, 
	OrganizationNode.ToString() AS pathNode,
	*
FROM HumanResources.Employee
ORDER BY OrganizationNode

-- 4
select SellStartDate, ProductLine, * 
from production.Product
WHERE ProductLine = 'T' AND SellStartDate IS NOT NULL

-- 5
select 
	SalesOrderID, CustomerID, OrderDate, SubTotal, TaxAmt,
	TaxAmt / SubTotal * 100 AS tax_percent
from sales.SalesOrderHeader

-- 6
select distinct JobTitle
from HumanResources.Employee

-- 7
select CustomerID, SUM(Freight)
from Sales.SalesOrderHeader
group by CustomerID
order by CustomerID

-- 8
select 
	customerid, 
	SalesPersonID,
	sum(SubTotal),
	AVG(SubTotal)
from sales.SalesOrderHeader
group by CustomerID, SalesPersonID
order by CustomerID

-- 9
select 
	ProductID,
	sum(Quantity)
from production.ProductInventory
where Shelf in ('A', 'C', 'H')
group by ProductID
having sum(Quantity) > 500
order by ProductID

-- 11
select p.LastName, pp.[PhoneNumber]
from person.Person p
left join person.PersonPhone pp on pp.BusinessEntityID = p.BusinessEntityID
where p.LastName like 'L%'

-- 12: ROLLUP operator
SELECT salespersonid, customerid, sum(subtotal) AS sum_subtotal
FROM sales.salesorderheader s 
GROUP BY ROLLUP (salespersonid, customerid);

SELECT salespersonid, customerid, sum(subtotal) AS sum_subtotal
FROM sales.salesorderheader s 
GROUP BY salespersonid, customerid
order by SalesPersonID, CustomerID


-- 13: CUBE operator
SELECT locationid, shelf, SUM(quantity) AS TotalQuantity
FROM production.productinventory
GROUP BY CUBE (locationid, shelf);

SELECT locationid, shelf, SUM(quantity) AS TotalQuantity
FROM production.productinventory
GROUP BY locationid, shelf;


-- 14: GROUPING SETS ( ROLLUP (locationid, shelf), CUBE (locationid, shelf) ) === CUBE (locationid, shelf)
-- ROLLUP(locationid, shelf) is just the subset of CUBE (locationid, shelf)
SELECT locationid, shelf, SUM(quantity) AS TotalQuantity
FROM production.productinventory
GROUP BY GROUPING SETS ( ROLLUP (locationid, shelf), CUBE (locationid, shelf) )

SELECT locationid, shelf, SUM(quantity) AS TotalQuantity
FROM production.productinventory
GROUP BY GROUPING SETS ( ROLLUP (locationid, shelf), CUBE (locationid, shelf) )
EXCEPT
SELECT locationid, shelf, SUM(quantity) AS TotalQuantity
FROM production.productinventory
GROUP BY CUBE (locationid, shelf)
ORDER BY locationid, shelf


-- 15: grouping set incluse custom combination of columns (for each locationId and grant total)
select LocationID, sum(Quantity)
from Production.ProductInventory
group by grouping sets (LocationID, ())


-- 16:
select a.city, count(p.BusinessEntityID) as [count]
from Person.BusinessEntityAddress p
inner join Person.Address a on a.AddressID = p.AddressID
group by a.City


-- 17:
select year(OrderDate), sum(TotalDue)
from sales.SalesOrderHeader
group by year(OrderDate)


-- 18:
select year(OrderDate), sum(TotalDue)
from sales.SalesOrderHeader
where orderdate	<= '2023-12-31'
group by year(OrderDate)


-- 19:
select ContactTypeID, [Name]
from person.ContactType
where [name] like '%Manager%'


-- 20:
select 
	p.BusinessEntityID,
	p.LastName,
	p.FirstName
from Person.ContactType ct
inner join Person.BusinessEntityContact ec on ec.ContactTypeID = ct.ContactTypeID
left join Person.Person p on p.BusinessEntityID = ec.PersonID
where ct.[Name] = 'Purchasing Manager'



-- 21:
select 
	ROW_NUMBER() OVER(PARTITION BY a.postalcode order by sp.salesytd desc) as rn,
	p.LastName,
	sp.SalesYTD,
	a.PostalCode
from Person.BusinessEntity be
inner join sales.SalesPerson sp on sp.TerritoryID is not null AND sp.SalesYTD <> 0 AND sp.BusinessEntityID = be.BusinessEntityID
left join Person.Person p on p.BusinessEntityID = be.BusinessEntityID
left join Person.BusinessEntityAddress br on br.BusinessEntityID = be.BusinessEntityID
left join Person.Address a on a.AddressID = br.AddressID
order by a.PostalCode asc

SELECT 
    ROW_NUMBER() OVER win AS "Row Number",
    pp.LastName, 
    sp.SalesYTD, 
    pa.PostalCode
FROM Sales.SalesPerson AS sp
    INNER JOIN Person.Person AS pp
        ON sp.BusinessEntityID = pp.BusinessEntityID
    INNER JOIN Person.BusinessEntityAddress AS pba
        ON sp.BusinessEntityID = pba.BusinessEntityID
    INNER JOIN Person.Address AS pa
        ON pba.AddressID = pa.AddressID
WHERE sp.TerritoryID IS NOT NULL
    AND sp.SalesYTD <> 0
WINDOW win AS (PARTITION BY pa.PostalCode ORDER BY sp.SalesYTD DESC)
ORDER BY pa.PostalCode;



-- 22:
select 
	t.ContactTypeID,
	t.Name,
	COUNT(c.BusinessEntityID) AS no_contacts
from Person.ContactType t
left join Person.BusinessEntityContact c on c.ContactTypeID = t.ContactTypeID
group by t.ContactTypeID, t.Name
having COUNT(c.BusinessEntityID) >= 100


-- 23:
select 
	format(h.RateChangeDate, 'd') as fromdate_format_d,
	cast(h.RateChangeDate as varchar(10)) as fromdate_cast,
	format(h.RateChangeDate, 'yyyy-MM-dd') as fromdate_format,
	convert(varchar(10), h.RateChangeDate, 23) as fromdate_convert_23,
	CONCAT(p.FirstName, ', ' + p.MiddleName, ' ', p.LastName) as nameinfull,
	h.Rate * 40 AS salaryinweek
from HumanResources.EmployeePayHistory h
inner join Person.Person p on p.BusinessEntityID = h.BusinessEntityID
order by nameinfull asc



-- 24:
with cte_prep as (
	select 
		row_number() over(partition by h.BusinessEntityID order by h.RateChangeDate desc) as rn,
		convert(varchar(10), h.RateChangeDate, 23) as fromdate,
		CONCAT(p.FirstName, ', ' + p.MiddleName, ' ', p.LastName) as nameinfull,
		h.Rate * 40 AS salaryinweek
	from HumanResources.EmployeePayHistory h
	inner join Person.Person p on p.BusinessEntityID = h.BusinessEntityID
)
select 
	fromdate,
	nameinfull,
	salaryinweek
from cte_prep
where rn = 1
order by nameinfull asc


-- 25:
select 
	SalesOrderID, 
	ProductID,
	OrderQty,
	sum(OrderQty) over win as sum_,
	avg(OrderQty) over win as avg_,
	count(OrderQty) over win as count_,
	max(OrderQty) over win as max_,
	min(OrderQty) over win as min_
from sales.SalesOrderDetail
where SalesOrderID in (43659, 43664)
window win as (partition by SalesOrderID)


-- 26:
select 
	SalesOrderID, 
	ProductID,
	OrderQty,
	SUM(OrderQty) OVER (ORDER BY SalesOrderID, ProductID) AS Total,
	AVG(OrderQty) OVER(PARTITION BY SalesOrderID ORDER BY SalesOrderID, ProductID) AS Avg,
	COUNT(OrderQty) OVER(ORDER BY SalesOrderID, ProductID ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING) AS Count
from sales.SalesOrderDetail
where SalesOrderID in (43659, 43664) and cast(ProductID as varchar) like '71%'


-- 27:
select 
	SalesOrderID,
	sum(UnitPrice * OrderQty) as total
from sales.SalesOrderDetail
group by SalesOrderID
having sum(UnitPrice * OrderQty) > 100000



-- 28:
select
	ProductID, Name
from production.Product
where Name like 'Lock Washer%'



-- 29:
select
	ProductID,
	Name,
	Color
from Production.Product
order by ListPrice


-- 30:
select 
	BusinessEntityID, JobTitle, HireDate
from HumanResources.Employee
order by datepart(YEAR, HireDate) asc


-- 32:
select 
	BusinessEntityID,
	SalariedFlag
from HumanResources.Employee
order by 
	case SalariedFlag
		when 'true' then BusinessEntityID 
	end desc,
	case SalariedFlag
		when 'false' then BusinessEntityID
	end asc


-- 33:
select
	BusinessEntityID, LastName, TerritoryName, CountryRegionName 
from sales.vSalesPerson
WHERE TerritoryName IS NOT NULL  
order by 
	case CountryRegionName
		when 'United States' then TerritoryName
		else CountryRegionName
	end


-- 34:
select
	p.FirstName,
	p.LastName,
	ROW_NUMBER() OVER(order by a.Postalcode) as [Row Number],
	RANK() OVER(order by a.Postalcode) as [Rank],
	DENSE_RANK() OVER(order by a.Postalcode) as [Dense rank],
	NTILE(4) OVER(order by a.Postalcode) as [Quatile],
	sp.SalesYTD,
	a.PostalCode
from sales.SalesPerson sp
inner join Person.Person p on p.BusinessEntityID = sp.BusinessEntityID
inner join Person.BusinessEntityAddress ba on ba.BusinessEntityID = sp.BusinessEntityID
inner join Person.Address a on a.AddressID = ba.AddressID
where sp.TerritoryID is not null and sp.SalesYTD <> 0


-- 35
SELECT *
from HumanResources.Department
order by DepartmentID
offset 10 rows


-- 36
select *
from HumanResources.Department
order by DepartmentID
offset 5 rows
fetch next 5 rows only



-- 38
select p.Name, d.SalesOrderDetailID
from sales.SalesOrderDetail d
full outer join production.product p on p.ProductID = d.ProductID



-- 46:
select 
	SalesPersonID,
	COUNT(*) as totalsales,
	YEAR(OrderDate) AS salesyear
from sales.SalesOrderHeader
group by SalesPersonID, YEAR(OrderDate)
order by SalesPersonID, YEAR(OrderDate) asc


-- 47
;
with cte_prep as (
	select count(*) as [count]
	from sales.SalesOrderHeader
	where SalesPersonID is not null
	group by SalesPersonID
)
select avg([count]) from cte_prep
;



-- 48: % -> matches any sequence of characters, _ -> matches any single character
-- => to use _ as matching character, using escape character before _
select *
from production.ProductPhoto
where LargePhotoFileName like '%greena_%' ESCAPE 'a'



-- 50:
select 
	JobTitle, HireDate
from HumanResources.Employee
order by HireDate DESC
offset 0 rows
fetch next 20 rows only


-- 51:
select
	d.OrderQty,
	d.UnitPriceDiscount,
	h.TotalDue
from sales.SalesOrderHeader h
join sales.SalesOrderDetail d on d.SalesOrderID = h.SalesOrderID
where (d.OrderQty > 5 OR d.UnitPriceDiscount < 1000)
	AND h.TotalDue > 1000


-- 52:
select Name, Color
from Production.Product
where name like '%red%'


-- 53:
select Name, ListPrice
from Production.Product
where ListPrice = 80.99 and name like '%Mountain%'

-- 56:
select 
	name,
	PATINDEX('chain[^a-z]%', name)
from Production.Product
where name like 'chain' or PATINDEX('chain[^a-z]%', name) > 0

-- 57:
select name, color
from Production.Product
where name like 'chain' or PATINDEX('chain[^a-z]%', name) > 0 or name like 'full%'


-- 58:
select concat(p.FirstName, ' ', p.LastName) || CHAR(13) || CHAR(10) || a.EmailAddress
from Person.Person p 
inner join Person.EmailAddress a on a.BusinessEntityID = p.BusinessEntityID


-- 59:
select 
	name,
	CHARINDEX('yellow', name) as substring_position
from Production.Product
where name like '%yellow%'


-- 60:
select 
	concat(name, ', color: ', color, ', Product Number: ', productnumber)
from Production.Product


-- 61:
select CONCAT_WS(',', name,ProductNumber, Color, char(13) + char(10))
from Production.Product


-- 62:
select left(name, 5)
from Production.Product


-- 63:
select 
	firstname,
	len(firstname)
from sales.vIndividualCustomer


-- 65:
select Name, UPPER(name) as _upper, LOWER(name) as _lower
from Production.Product
where ListPrice between 1000 and 1220


-- 66:
select
	'     five space then the text' as org,
	LTRIM('     five space then the text') as lt_org


-- 67:
select 
	ProductNumber,
	substring(ProductNumber, 3, len(ProductNumber)) as _substring,
	LTRIM(ProductNumber, 'HN') as _ltrim
from Production.Product
where ProductNumber like 'HN%'


-- 68:
select 
	Name,
	productline,
	concat(REPLICATE('0', 4), ProductLine)
from Production.Product
where ProductLine = 'T'


-- 69:
select
	FirstName,
	REVERSE(FirstName)
from person.Person
where BusinessEntityID < 6


-- 70:
select 
	Name,
	ProductNumber,
	RIGHT(name, 8) as _right
from Production.Product
order by ProductNumber asc


-- 71: 
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


-- 72:
select
	productnumber,
	name
from Production.Product
where name COLLATE Latin1_General_CS_AS like '%[SML]'


-- 73:
select STRING_AGG(CAST(coalesce(FirstName, 'N/A') AS VARCHAR(MAX)), ', ')
from Person.Person


-- 74:
select STRING_AGG(cast(coalesce(FirstName, 'N/A') + ' ' + convert(varchar(19), ModifiedDate, 120) as varchar(max)), ', ')
from person.Person


-- 75:
select top 10
	City,
	STRING_AGG(cast(e.EmailAddress as varchar(max)), ';') as emails
from person.EmailAddress e
inner join Person.BusinessEntityAddress b on b.BusinessEntityID = e.BusinessEntityID
inner join Person.Address a on a.AddressID = b.AddressID
group by a.City


-- 76:
select
	jobtitle,
	REPLACE(jobtitle, 'Production Assistant', 'Production Supervisor') AS [New Jobtitle]
from HumanResources.Employee
where JobTitle like '%Production Assistant%'


-- 77:
select
	SUBSTRING(JobTitle, 1, 5),
	JobTitle,
	*
from HumanResources.Employee
where SUBSTRING(JobTitle, 1, 5) = 'sales'


-- 80:
select
	Name,
	ListPrice
from Production.Product
where cast(ListPrice as varchar) like '33%'


-- 81:
select
	SalesYTD,
	CommissionPct,
	round(SalesYTD / CommissionPct, 0) as computed
from sales.SalesPerson
where CommissionPct <> 0


-- 86:
select 
	TerritoryID,
	avg(Bonus) as [average bonus],
	sum(SalesYTD) as [YTD sales]
from sales.SalesPerson
group by TerritoryID


-- 87:
select
	avg(distinct ListPrice) as [avg]
from Production.Product


-- 92:
select 
	count(*),
	avg(bonus)
from sales.SalesPerson
where SalesQuota > 25000


-- 95:
select distinct 
	COUNT(Productid) OVER(PARTITION BY SalesOrderid) as product_count_distinct,
	SalesOrderID
from sales.SalesOrderDetail
where SalesOrderID in (43855, 43661)

select 
	COUNT(Productid),
	SalesOrderID
from sales.SalesOrderDetail
where SalesOrderID in (43855, 43661)
group by SalesOrderID


-- 96:
;
with cte_prep as (
	select 
		QuotaDate,
		YEAR(QuotaDate) AS year_,
		DATEPART(QUARTER, QuotaDate) as quarter_,
		SalesQuota ,
		avg(SalesQuota) over(partition by YEAR(QuotaDate)) as mean
	from sales.salespersonquotahistory
	where businessentityid = 277
)
	select 
		year_,
		quarter_,
		SalesQuota,
		sum(power(SalesQuota - mean, 2)) over(partition by year_) / count(*) over(partition by year_) as variance_population,
		var(SalesQuota) over(partition by year_ order by quarter_) as variance_var1,
		var(SalesQuota) over(partition by year_) as variance_var2,
		varp(SalesQuota) over(partition by year_ order by quarter_) as variance_varp1,
		varp(SalesQuota) over(partition by year_) as variance_varp2
	from cte_prep
	order by QuotaDate asc



-- 97:
select 
	var(SalesQuota) as variance_var,
	var(distinct SalesQuota) as variance_var_d,
	varp(distinct SalesQuota) as variance_varp_d,
	varp(SalesQuota) as variance_varp
from sales.salespersonquotahistory


-- 98:



-- 101:
select 
	d.Department,
	d.LastName,
	p.Rate,
	CUME_DIST() OVER(partition by department order by rate ASC) as [cumulative distribution asc],
	PERCENT_RANK() over(partition by department order by rate asc) as [percent rank asc],
	CUME_DIST() OVER(partition by department order by rate DESC) as [cumulative distribution desc],
	PERCENT_RANK() over(partition by department order by rate DESC) as [percent rank desc]
from HumanResources.vEmployeeDepartmentHistory d
inner join HumanResources.EmployeePayHistory p on p.BusinessEntityID = d.BusinessEntityID


-- 102:
select 
	Name,
	ListPrice,
	Name AS LeastExpensive
from Production.Product
where ProductSubcategoryID = 37
	AND ListPrice = (select min(listprice) from Production.Product where ProductSubcategoryID = 37)


-- 103:
with cte_emp as (
	select 
		BusinessEntityID,
		JobTitle,
		VacationHours,
		rank() over(partition by JobTitle order by VacationHours  asc) as r
	from HumanResources.Employee
)
select
	cte.JobTitle,
	p.LastName,
	cte.VacationHours
from cte_emp cte
inner join Person.Person p on cte.BusinessEntityID = p.BusinessEntityID and cte.r = 1

select 
	JobTitle,
	LastName,
	VacationHours,
	FIRST_VALUE(LastName) over(partition by jobtitle order by vacationhours asc
							rows unbounded preceding) As fewestvacationhours
from HumanResources.Employee e
inner join Person.person p on p.BusinessEntityID = e.BusinessEntityID
order by JobTitle



-- 104:
select 
	BusinessEntityID,
	year(QuotaDate) as salesyear,
	SalesQuota,
	lag(SalesQuota, 1, 0) over(partition by businessentityid order by quotadate asc) as prev_quota
from sales.SalesPersonQuotaHistory


-- 105:
select 
	TerritoryName,
	BusinessEntityID,
	SalesYTD
from sales.vSalesPerson
order by TerritoryName


-- 106:
select 
	vh.Department,
	vh.LastName,
	h.Rate,
	e.HireDate,
	LAST_VALUE(HireDate) over(partition by vh.Department order by h.Rate
								rows between unbounded preceding and unbounded following) as lastvalue_allwindow,
	LAST_VALUE(HireDate) over(partition by vh.Department order by h.Rate) as lastvalue_expand_window
from HumanResources.vEmployeeDepartmentHistory vh
inner join HumanResources.EmployeePayHistory h on h.BusinessEntityID = vh.BusinessEntityID
inner join HumanResources.Employee e on e.BusinessEntityID = h.BusinessEntityID
where vh.Department in ('Information Services', 'Document Control')



-- 107:
select
	BusinessEntityID,
	DATEPART(QUARTER, QuotaDate) as [quarter],
	DATEPART(YEAR, QuotaDate) as [year],
	SalesQuota,
	FIRST_VALUE(SalesQuota) over(partition by BusinessEntityID, DATEPART(YEAR, QuotaDate) order by QuotaDate ASC
						ROWS BETWEEN unbounded PRECEDING AND CURRENT ROW) as first_quarter_sales,
	LAST_VALUE(SalesQuota) over(partition by BusinessEntityID, DATEPART(YEAR, QuotaDate) order by QuotaDate ASC
						ROWS BETWEEN current row AND UNBOUNDED FOLLOWING) as last_quarter_sales,
	SalesQuota - FIRST_VALUE(SalesQuota) over(partition by BusinessEntityID, DATEPART(YEAR, QuotaDate) order by QuotaDate ASC
						ROWS BETWEEN unbounded PRECEDING AND UNBOUNDED FOLLOWING) as first_sales_diff,
	SalesQuota - LAST_VALUE(SalesQuota) over(partition by BusinessEntityID, DATEPART(YEAR, QuotaDate) order by QuotaDate ASC
						RANGE BETWEEN unbounded PRECEDING AND UNBOUNDED FOLLOWING) as last_sales_diff
from sales.SalesPersonQuotaHistory
where BusinessEntityID >= 274 AND BusinessEntityID <= 275
order by BusinessEntityID, DATEPART(YEAR, QuotaDate), DATEPART(QUARTER, QuotaDate)


-- 108:
select 
	DATEPART(YEAR, QuotaDate) as [year],
	DATEPART(QUARTER, QuotaDate) as [quarter],
	SalesQuota,
	VARP(SalesQuota) over(partition by DATEPART(YEAR, QuotaDate) order by QuotaDate asc)
from sales.SalesPersonQuotaHistory
where BusinessEntityID = 277
order by [year], [quarter]


-- 109:
select 
	BusinessEntityID,
	YEAR(QuotaDate),
	SalesQuota,
	LEAD(SalesQuota, 1, 0) over(order by QuotaDate ASC) as next_quota
from sales.SalesPersonQuotaHistory
where BusinessEntityID = 277


-- 110:
select 
	TerritoryName,
	BusinessEntityID,
	SalesYTD,
	LEAD(SalesYTD, 1, 0) over(partition by TerritoryName order by SalesYTD desc) as next_person_quota
from sales.vSalesPerson 



-- 112:
select 
	Department,
	LastName,
	rate,
	CUME_DIST() OVER(partition by Department order by rate asc) as cumedist,
	PERCENT_RANK() over(partition by department order by rate asc) as percentrank
from HumanResources.vEmployeeDepartmentHistory d
inner join HumanResources.EmployeePayHistory p on p.BusinessEntityID = d.BusinessEntityID
where d.Department in ('Information Services', 'Document Control')
order by department, rate desc


-- 113:
select
	SalesOrderID,
	OrderDate,
	DATEADD(DAY, 2, OrderDate) as promisedshipdate
from sales.SalesOrderHeader



-- 115:
select
	DATEDIFF(DAY, min(OrderDate), max(OrderDate)) as date_diff
from sales.SalesOrderHeader



-- 116:
select 
	i.ProductID,
	p.Name,
	i.LocationID,
	i.Quantity,
	DENSE_RANK() OVER(partition by i.LocationID order by i.Quantity desc)
from Production.ProductInventory i
inner join Production.Product p on p.ProductID = i.ProductID
where LocationID in (3, 4)



-- 117:
select TOP 10
	BusinessEntityID,
	Rate,
	DENSE_RANK() over(order by rate desc) as rankbysalary
from HumanResources.EmployeePayHistory
;
select
	BusinessEntityID,
	Rate,
	DENSE_RANK() over(order by rate desc) as rankbysalary
from HumanResources.EmployeePayHistory
order by rankbysalary asc
offset 0 rows
fetch next 10 rows only



-- 118:
select
	FirstName,
	LastName,
	SalesYTD,
	NTILE(4) over(order by SalesYTD) as quartile
from sales.SalesPerson sp
inner join Person.Person p ON p.BusinessEntityID = sp.BusinessEntityID


-- 119:
select 
	p.ProductID,
	p.Name,
	i.LocationID,
	i.Quantity,
	RANK() OVER(partition by i.LocationID order by i.Quantity desc) as [rank]
from Production.ProductInventory i
inner join Production.Product p on p.ProductID = i.ProductID
where LocationID in (3, 4)


-- 120:
with cte_prep as (
	select 
		BusinessEntityID,
		Rate,
		ROW_NUMBER() over(partition by BusinessEntityID order by RateChangeDate desc) as rn
	from HumanResources.EmployeePayHistory
)
select top 10
	BusinessEntityID,
	Rate,
	RANK() over(order by Rate desc) as rankbysalary
from cte_prep
where rn = 1



SELECT top 10
    -- Selecting the BusinessEntityID column
    BusinessEntityID, 

    -- Selecting the Rate column
    Rate,   

    -- Calculating the rank of Rate in descending order
    RANK() OVER (ORDER BY Rate DESC) AS RankBySalary  

-- Selecting data from the EmployeePayHistory table aliased as eph1
FROM 
    HumanResources.EmployeePayHistory AS eph1  

-- Filtering records where RateChangeDate matches the maximum RateChangeDate for each BusinessEntityID
WHERE 
    RateChangeDate = (
        -- Subquery to get the maximum RateChangeDate for each BusinessEntityID
        SELECT MAX(RateChangeDate)   
        FROM HumanResources.EmployeePayHistory AS eph2  
        WHERE eph1.BusinessEntityID = eph2.BusinessEntityID
    )  

-- Ordering the result set by BusinessEntityID
ORDER BY 
    BusinessEntityID