SELECT DISTINCT TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES



---------------------------------------------------
-------- EXPLORE SCHEMA HumanResources ------------
---------------------------------------------------
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'HumanResources'
ORDER BY TABLE_NAME

SELECT TOP 100 * FROM HumanResources.Employee
EXEC sp_helpindex 'HumanResources.Employee'


-- Information of employee in department
SELECT TOP 100 * FROM HumanResources.Employee
SELECT TOP 100 * FROM HumanResources.Department
SELECT TOP 100 * FROM HumanResources.EmployeeDepartmentHistory
SELECT TOP 100 * FROM HumanResources.Shift

-- Thêm thông tin shift
INSERT INTO HumanResources.EmployeeDepartmentHistory(BusinessEntityID, DepartmentID, ShiftID, StartDate, EndDate, ModifiedDate)
VALUES(4, 2, 3, '2010-05-31', NULL, GETDATE())
INSERT INTO HumanResources.EmployeeDepartmentHistory(BusinessEntityID, DepartmentID, ShiftID, StartDate, EndDate, ModifiedDate)
VALUES(1, 16, 3, '2009-01-14', NULL, GETDATE())


-- Query information of employees and their works
SELECT 
	ROW_NUMBER() OVER(PARTITION BY e.BusinessEntityID ORDER BY e.BusinessEntityID) AS rn,
	e.BusinessEntityID AS emp_BusinessEntityID,
	e.NationalIDNumber AS emp_NationalIDNumber, 
	e.LoginID AS emp_LoginID, 
	e.JobTitle AS emp_JobTitle, 
	e.HireDate AS emp_HireDate,
	edh.StartDate AS edh_StartDate,
	d.Name AS d_Name,
	d.GroupName AS d_GroupName,
	s.Name AS s_Name,
	s.StartTime AS s_StartTime,
	s.EndTime AS s_EndTime
FROM HumanResources.Employee e
LEFT JOIN HumanResources.EmployeeDepartmentHistory edh ON edh.BusinessEntityID = e.BusinessEntityID
LEFT JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID
LEFT JOIN HumanResources.[Shift] s ON s.ShiftID = edh.ShiftID


-- Query all employees who has worked at more than 1 departent
SELECT * FROM (
	SELECT 
		ROW_NUMBER() OVER(PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate) AS rn,
		COUNT(d.[Name]) OVER(PARTITION BY e.BusinessEntityID) AS count_businessE,
		COUNT(d.[Name]) OVER(PARTITION BY e.BusinessEntityID, d.[Name]) AS count_bE_dE,
		e.BusinessEntityID AS emp_BusinessEntityID,
		e.NationalIDNumber AS emp_NationalIDNumber, 
		e.LoginID AS emp_LoginID, 
		e.JobTitle AS emp_JobTitle, 
		e.HireDate AS emp_HireDate,
		edh.StartDate AS edh_StartDate,
		edh.EndDate AS edh_EndDate,
		d.Name AS d_Name,
		d.GroupName AS d_GroupName,
		s.Name AS s_Name,
		s.StartTime AS s_StartTime,
		s.EndTime AS s_EndTime
	FROM HumanResources.Employee e
	LEFT JOIN HumanResources.EmployeeDepartmentHistory edh ON edh.BusinessEntityID = e.BusinessEntityID
	LEFT JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID
	LEFT JOIN HumanResources.[Shift] s ON s.ShiftID = edh.ShiftID
) temp
WHERE temp.count_businessE > 1 AND temp.count_businessE <> temp.count_bE_dE
ORDER BY temp.emp_BusinessEntityID ASC, temp.rn ASC


-- Query the employee’s working information from the Departments and Shifts tables. 
-- The result must return only one row for each employee. 
-- For each row, represent the employee’s working timeline as columns, pivoted over the department’s start date and the shift’s start time. 
-- The output should display department and shift assignments in chronological order, 
--	with columns labeled sequentially (e.g., Department1, Shift1, Shift2, Department2, Shift1, …)

-- SOLUTION 1: multi pivot
SELECT 
	MAX(piv5.emp_BusinessEntityID) AS emp_BusinessEntityID, 
	MAX(piv5.emp_NationalIDNumber) AS emp_NationalIDNumber, 
	MAX(piv5.emp_LoginID) AS emp_LoginID, 
	MAX(piv5.emp_JobTitle) AS emp_JobTitle, 
	MAX(piv5.emp_HireDate) AS emp_HireDate, 

	MAX(piv5.Department1) AS Department1, 
	MAX(piv5.StartDate1) AS StartDate1,
	MAX(piv5.[ShiftName11]) AS [ShiftName11],
	MAX(piv5.[ShiftStart11]) AS [ShiftStart11],
	MAX(piv5.[ShiftEnd11]) AS [ShiftEnd11],
	MAX(piv5.[ShiftName12]) AS [ShiftName12],
	MAX(piv5.[ShiftStart12]) AS [ShiftStart12],
	MAX(piv5.[ShiftEnd12]) AS [ShiftEnd12],

	MAX(piv5.Department2) AS Department2, 
	MAX(piv5.StartDate2) AS StartDate2,
	MAX(piv5.[ShiftName21]) AS [ShiftName21],
	MAX(piv5.[ShiftStart21]) AS [ShiftStart21],
	MAX(piv5.[ShiftEnd21]) AS [ShiftEnd21],
	MAX(piv5.[ShiftName22]) AS [ShiftName22],
	MAX(piv5.[ShiftStart22]) AS [ShiftStart22],
	MAX(piv5.[ShiftEnd22]) AS [ShiftEnd22]
FROM (
	SELECT 
		e.BusinessEntityID AS emp_BusinessEntityID,
		e.NationalIDNumber AS emp_NationalIDNumber, 
		e.LoginID AS emp_LoginID, 
		e.JobTitle AS emp_JobTitle, 
		e.HireDate AS emp_HireDate,
		edh.StartDate AS edh_StartDate,
		d.Name AS d_Name,
		s.Name AS s_Name,
		s.StartTime AS s_StartTime,
		s.EndTime AS s_EndTime,

		'StartDate' + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate ASC) AS Nvarchar) AS StartDateTitle,
		'Department' + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate ASC) AS Nvarchar) AS DepartmentTitle,

		'ShiftName' + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate ASC) AS Nvarchar) + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID, d.Name ORDER BY s.StartTime ASC) AS Nvarchar) AS ShiftNameTitle,
		'ShiftStart' + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate ASC) AS Nvarchar) + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID, d.Name ORDER BY s.StartTime ASC) AS Nvarchar) AS ShiftStartTitle,
		'ShiftEnd' + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate ASC) AS Nvarchar) + CAST(DENSE_RANK() OVER(PARTITION BY e.BusinessEntityID, d.Name ORDER BY s.StartTime ASC) AS Nvarchar) AS ShiftEndTitle
	FROM HumanResources.Employee e
	LEFT JOIN HumanResources.EmployeeDepartmentHistory edh ON edh.BusinessEntityID = e.BusinessEntityID
	LEFT JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID
	LEFT JOIN HumanResources.Shift s ON s.ShiftID = edh.ShiftID
) src
PIVOT (
	MAX(src.edh_StartDate)
	FOR src.[StartDateTitle] IN ([StartDate1], [StartDate2])
) AS piv1
PIVOT (
	MAX(piv1.d_Name)
	FOR piv1.[DepartmentTitle] IN ([Department1], [Department2])
) AS piv2
PIVOT (
	MAX(piv2.s_Name)
	FOR piv2.ShiftNameTitle IN ([ShiftName11], [ShiftName12], [ShiftName21], [ShiftName22])
) AS piv3
PIVOT (
	MAX(piv3.s_StartTime)
	FOR piv3.ShiftStartTitle IN ([ShiftStart11], [ShiftStart12], [ShiftStart21], [ShiftStart22])
) AS piv4
PIVOT (
	MAX(piv4.s_EndTime)
	FOR piv4.ShiftEndTitle IN ([ShiftEnd11], [ShiftEnd12], [ShiftEnd21], [ShiftEnd22])
) AS piv5
GROUP BY piv5.emp_BusinessEntityID




-- SOLUTION 2: CASE-based pivot
SELECT 
	e.BusinessEntityID, 
	e.NationalIDNumber, 
	e.LoginID, 
	e.JobTitle, 
	e.HireDate, 
	MAX(CASE WHEN rnDept = 1 THEN e.depName END) AS Department1, 
	MAX(CASE WHEN rnDept = 1 THEN e.StartDate END) AS StartDate1, 
	MAX(CASE WHEN rnDept = 1 AND rnShift = 1 THEN e.shiftName END) AS ShiftName11, 
	MAX(CASE WHEN rnDept = 1 AND rnShift = 1 THEN e.StartTime END) AS ShiftStart11, 
	MAX(CASE WHEN rnDept = 1 AND rnShift = 1 THEN e.EndTime END) AS ShiftEnd11, 
	MAX(CASE WHEN rnDept = 1 AND rnShift = 2 THEN e.shiftName END) AS ShiftName12, 
	MAX(CASE WHEN rnDept = 1 AND rnShift = 2 THEN e.StartTime END) AS ShiftStart12, 
	MAX(CASE WHEN rnDept = 1 AND rnShift = 2 THEN e.EndTime END) AS ShiftEnd12, 
	MAX(CASE WHEN rnDept = 2 THEN e.depName END) AS Department2, 
	MAX(CASE WHEN rnDept = 2 THEN e.StartDate END) AS StartDate2, 
	MAX(CASE WHEN rnDept = 2 AND rnShift = 1 THEN e.shiftName END) AS ShiftName21, 
	MAX(CASE WHEN rnDept = 2 AND rnShift = 1 THEN e.StartTime END) AS ShiftStart21, 
	MAX(CASE WHEN rnDept = 2 AND rnShift = 1 THEN e.EndTime END) AS ShiftEnd21, 
	MAX(CASE WHEN rnDept = 2 AND rnShift = 2 THEN e.shiftName END) AS ShiftName22,
	MAX(CASE WHEN rnDept = 2 AND rnShift = 2 THEN e.StartTime END) AS ShiftStart22, 
	MAX(CASE WHEN rnDept = 2 AND rnShift = 2 THEN e.EndTime END) AS ShiftEnd22
FROM ( 
	SELECT 
		e.BusinessEntityID, 
		e.NationalIDNumber, 
		e.LoginID, 
		e.JobTitle, 
		e.HireDate, 
		edh.StartDate, 
		d.Name AS depName, 
		s.Name AS shiftName, 
		s.StartTime,
		s.EndTime,
		ROW_NUMBER() OVER (PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate) AS rnDept, 
		ROW_NUMBER() OVER (PARTITION BY e.BusinessEntityID, d.Name ORDER BY s.StartTime) AS rnShift 
	FROM HumanResources.Employee e 
	LEFT JOIN HumanResources.EmployeeDepartmentHistory edh ON edh.BusinessEntityID = e.BusinessEntityID 
	LEFT JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID 
	LEFT JOIN HumanResources.Shift s ON s.ShiftID = edh.ShiftID 
) e
GROUP BY BusinessEntityID, NationalIDNumber, LoginID, JobTitle, HireDate;




-- SOLUTION 3: combined CROSS APPLY with PIVOT
WITH CTE_PREP AS (
	SELECT 
		e.BusinessEntityID, 
		e.NationalIDNumber, 
		e.LoginID, 
		e.JobTitle, 
		e.HireDate, 
		edh.StartDate, 
		d.[Name] AS depName, 
		s.Name AS shiftName, 
		s.StartTime,
		s.EndTime,
		CAST(DENSE_RANK() OVER (PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate) AS VARCHAR) AS str_rnDept,
		CAST(DENSE_RANK() OVER (PARTITION BY e.BusinessEntityID, d.Name ORDER BY s.StartTime) AS VARCHAR) AS str_rnShift,
		DENSE_RANK() OVER (PARTITION BY e.BusinessEntityID ORDER BY edh.StartDate) AS rnDept, 
		DENSE_RANK() OVER (PARTITION BY e.BusinessEntityID, d.Name ORDER BY s.StartTime) AS rnShift 
	FROM HumanResources.Employee e 
	LEFT JOIN HumanResources.EmployeeDepartmentHistory edh ON edh.BusinessEntityID = e.BusinessEntityID 
	LEFT JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID 
	LEFT JOIN HumanResources.Shift s ON s.ShiftID = edh.ShiftID
), 
CTE_PREP2 AS (
	SELECT 
		cte.BusinessEntityID, 
		cte.NationalIDNumber, 
		cte.LoginID, 
		cte.JobTitle, 
		cte.HireDate,
		temp.col,
		temp.val
	FROM CTE_PREP cte
	CROSS APPLY (
		VALUES('Department' + cte.str_rnDept, cte.depName),
			  ('StartDate' + cte.str_rnDept, CAST(cte.StartDate AS VARCHAR)),
			  ('ShiftName' + cte.str_rnDept + cte.str_rnShift, cte.shiftName),
			  ('ShiftStart' + cte.str_rnDept + cte.str_rnShift, CAST(cte.StartTime AS VARCHAR)),
			  ('ShiftEnd' + cte.str_rnDept + cte.str_rnShift, CAST(cte.EndTime AS VARCHAR))
	) temp (col, val)
)
SELECT 
	*
FROM CTE_PREP2 AS src
PIVOT (
	MAX(val) 
	FOR col IN ([Department1] , [StartDate1], [ShiftName11], [ShiftStart11], [ShiftEnd11], [ShiftName12], [ShiftStart12], [ShiftEnd12],
		[Department2] , [StartDate2], [ShiftName21], [ShiftStart21], [ShiftEnd21], [ShiftName22], [ShiftStart22], [ShiftEnd22])
) AS piv