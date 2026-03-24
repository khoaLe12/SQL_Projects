

-- XML DATA
-- 1. SQL Server provides a powerful platform to work with XML
--	+ XML data can be stored natively in an xml data type column
--	+ XML data can be typed according to a collection of XML schemas, or left untyped.
--	+ Support querying XML data through XQuery.
--	+ Enhancements to OPENROWSET to allow bulk loading of XML data.
--	+ The ability to parse between relational data and XML data
--	+ XML columns can be compressed and indexed.
--	+ Preserve the document order and document structure, elements and attributes values, namespace prefixes, and XML declaration.
--	+ The structure is effecient for fine-grained query like extracting some of the sections within XML document using predicate evaluation.
--	+ Effectively modifying/inserting new sections without replacing whole document, and the oprerations are performed in a transacted way.
--	+ Guarantee the XML data format by validate input with XML schemas.
--	+ Indexes on XML data type increases the query processing.
--	+ More flexible than relational structure if the structure is frequently changed.
-- 3. XML storage options:
--	+ Natively store xml data type, improves parsing speed significantly through PSVI
--	+ Using an annotated schema (AXSD) to decompose XML into columns, create a copy of XML data (called XML view) is stored at the relational level.
--	+ Data is stored as large object storage, [n]varchar(max) and varbinary(max) which create an identical copy of data. 
-- 4. Typed XML instance has a collection of XML schema associated with it, provide more benefits compared to untyped XML.
--	+ The XML schema collection can be associated with variables, parameters, or columns of the xml data type.
--	+ The ability to define validation constraints when creating or modifying XML instance.
--	+ Store information of data types of attributes and elements in an instance, make it more adventages to query the know type of data with more precise operational semantics.
--	+ Allow declaring an XML instance with a specific facet are DOCUMENT and CONTENT, CONTENT is the default option.
--	+ Document XML restricts the xml instance to have exactly one top-level element.
--	+ Content XML can contain zero or many top-level elements or even text nodes.
-- 5. SQL Server stores and return XML data in Unicode (UTF-16) encoding
--	+ If a source code page does not specify the encoding in the string, an its encoding isn't Unicode, the parsing could cause error
--	+ To explicitly specify encoding for a source code page, prepending XML declaration with encoding to the XML document




-- PRACTICE
USE AdventureWorks2014
GO


-- Create instances of XML data
SELECT CONVERT(XML, '<Cust><Fname>Andrew</Fname><Lname>Fuller</Lname></Cust>');
GO

SELECT 
	DepartmentID,
	Name,
	GroupName,
	ModifiedDate
FROM HumanResources.Department
FOR XML AUTO, TYPE
GO

DECLARE @s varchar(MAX) = 
N'<products>
  <product id="1">
    <name>Café au lait</name>
    <price>2.50</price>
  </product>
  <product id="2">
    <name>Crème brûlée</name>
    <price>5.00</price>
  </product>
</products>'
SELECT CAST(
	CAST(('<?xml version="1.0" encoding="iso8859-1"?>' + @s) AS VARBINARY (MAX)) 
	AS XML) AS [xml data with encoding ISO‑8859‑1]
GO

SELECT BulkColumn AS [binary data stream]
FROM OPENROWSET(
	BULK 'D:\0. Khoa\0. SQL Projects\Notes\2. XML\SampleData1.txt',
	SINGLE_BLOB
) AS x
GO

SELECT CONVERT(XML, BulkColumn, 2) AS [xml data with DTD]
FROM OPENROWSET(
	BULK 'D:\0. Khoa\0. SQL Projects\Notes\2. XML\SampleData2.txt',
	SINGLE_BLOB
) AS x
GO


-- Specify constraint for XML column
CREATE OR ALTER FUNCTION dbo.afCheckExistsA_ProductID(@var XML)
RETURNS Bit
AS BEGIN
	RETURN @var.exist('/ProductDescription/@ProductID')
END;
GO

CREATE TABLE T1 (
	Col1 XML CHECK(dbo.afCheckExistsA_ProductID(Col1) = 1)
)
GO

INSERT INTO T1 VALUES('<ProductDescription ProductID="1" />');
GO


-- Associating a schema collection with a typed XML variable, parameter, column
DECLARE @x1 XML (DOCUMENT Production.ProductDescriptionSchemaCollection) ;
DECLARE @x2 XML (CONTENT Production.ProductDescriptionSchemaCollection);
GO

CREATE TABLE T1(
	Col1 Int,
	Col2 XML (Production.ProductDescriptionSchemaCollection) NOT NULL DEFAULT CAST(N'<element1></element1>' AS XML)
)
GO

CREATE PROCEDURE SampleProc
	@x XML (Production.ProductDescriptionSchemaCollection)
AS
GO


-- Query XML
-- Add namespaces to queries
WITH XMLNAMESPACES ('uri' AS ns1)
SELECT
	ProductID AS 'ns1:ProductID',
	Name AS 'ns1:Name',
	Color AS 'ns1:Color'
FROM Production.Product
WHERE ProductID IN (316, 317)
FOR XML RAW ('ns1:Prod'), ELEMENTS;


-- XML Modification
