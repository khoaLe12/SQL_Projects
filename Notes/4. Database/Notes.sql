USE master;
GO


-- Create a database with specify data file location, etc...
CREATE DATABASE Sales ON
(
	NAME = Sales_dat, -- this is primary file by default
	FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL17.SQLEXPRESS\MSSQL\DATA\saledat.mdf',
	SIZE = 10, -- MB type is used be default if MB or KB aren't specified
	MAXSIZE = 50,
	FILEGROWTH = 5
)
LOG ON
(
	NAME = Sales_log,
	FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL17.SQLEXPRESS\MSSQL\DATA\salelog.ldf',
	SIZE = 5 MB,
	MAXSIZE = 25 MB,
	FILEGROWTH = 5 MB
);
GO





-- View a list of databases
SELECT name, database_id, create_date
FROM sys.databases