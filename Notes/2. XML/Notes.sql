

-- XML DATA
-- 1. SQL Server provides a powerful platform to work with XML
--	+ XML data can be stored natively in an xml data type column
--	+ XML data can be typed according to a collection of XML schemas, or left untyped.
--	+ Support querying XML data through XQuery.
--	+ Enhancements to OPENROWSET to allow bulk loading of XML data.
--	+ The ability to parse between relational data and XML data
--	+ XML columns can be compressed (starting with SQL Server 2022) and indexed.
--	+ Preserve the document order and document structure, elements and attributes values, namespace prefixes, and XML declaration.
--	+ The structure is effecient for fine-grained query like extracting some of the sections within XML document using predicate evaluation.
--	+ Effectively modifying/inserting new sections without replacing whole document, and the oprerations are performed in a transacted way.
--	+ Guarantee the XML data format by validate input with XML schemas.
--	+ Indexes on XML data type increases the query processing.
--	+ More flexible than relational structure if the structure is frequently changed.
-- 2. XML storage options:
--	+ Natively store xml data type, improves parsing speed significantly through PSVI
--	+ Using an annotated schema (AXSD) to decompose XML into columns, create a copy of XML data (called XML view) is stored at the relational level.
--	+ Data is stored as large object storage, [n]varchar(max) and varbinary(max) which create an identical copy of data. 
-- 3. Typed XML instance has a collection of XML schema associated with it, provide more benefits compared to untyped XML.
--	+ The XML schema collection can be associated with variables, parameters, or columns of the xml data type.
--	+ The ability to define validation constraints when creating or modifying XML instance.
--	+ Store information of data types of attributes and elements in an instance, make it more adventages to query the know type of data with more precise operational semantics.
--	+ Allow declaring an XML instance with a specific facet are DOCUMENT and CONTENT, CONTENT is the default option.
--	+ Document XML restricts the xml instance to have exactly one top-level element.
--	+ Content XML can contain zero or many top-level elements or even text nodes.
-- 4. SQL Server stores and return XML data in Unicode (UTF-16) encoding
--	+ If a source code page does not specify the encoding in the string, an its encoding isn't Unicode, the parsing could cause error
--	+ To explicitly specify encoding for a source code page, prepending XML declaration with encoding to the XML document.
-- 5. XML Index:
--	+ Indexing XML data will affect all tags, values and paths over the XML instance.
--	+ Improve query performance but trade off with index maintenance cost.
--	+ XML indexes are defined as categories: Primary XML index and Secondary XML index
--	+ The primary index is a shredded representation of XML instance, it create a row for each node in XML object
--		+ Rows store all informations of a node: tag/element/attribute name, node type and its value, document order, path from node to the root
--		+ This stored information help query engine to quickly locate the specific node through its name and path.
--		+ Persist the representation of XML, avoid shredding XML binary large objects at run time.
--	+ The seondary indexes store additional data of XML, built from primary XML index, they are divided into three main types:
--		+ PATH secondary XML index: significantly speed up query that searching for paths
--		+ VALUE secondary XML index: benefits from querying specific node value without knowing the element and attribute names of the node, and the path is not fully specified or it includes a wildcard.
--		+ PROPERTY secondary XML index: best use in scenario of querying one or more values of object using value() method in the SELECT statement.
--	+ The Selective XML indexes:
--		+ 
-- 6. XML compression
--	+ Compress the XML data to a compressed format, but doesn't change XML data syntax and semantics.
--	+ XML data is compressed with the Xpress Compression Algorithm.
--	+ XML indexes are compressed using data compression.
-- 7. XML Schemas (XSD)
--	+ XML Schema collection contains a list of XML schemas, used to validate XML instances.
--	+ XML schema collection is a metadata of an instance, define all the data type information for the instance data.
--	+ XML schema can contains a various components like ELEMENT, ATTRIBUTE, SIMPLE TYPE, COMPLEX TYPE, ATTRIBUTEGROUP, MODELGROUP
--	+ SQL Server stores the defined components instead of XML it self.
--  +
-- 8. FOR XML
--  + SQL Server provides the FOR XML clause to parse the rowset results into XML document.
--  + The shape of the resulting XML can be explicitly specified with RAW, AUTO, EXPLICIT, or PATH modes.
--      + Use RAW[('ElementName')] mode to generates a single element per row, or construct XML hierarchy be writing nested FOR XML queries; by default the element tag use the identifier <row>.
--      + Use AUTO mode to generate nesting XML, the shape is based on the order of tables identified by the columns specified in the SELECT clause.
--      + Use EXPLICIT mode to mix attributes and elements, this mode allows to create more complex shape of XML (wrapper, nested properties, space-seperated values, mixed contents), but often result in cumbersome queries.
--      + Use PATH[('ElementName')] mode with the nested FOR XML query capability as a simpler alternative to the EXPLICIT mode; by default the mode generate a <row> element wrapper for each row, no wrapper element is generated if empty string is used.
--  + To defined the format of XML data, SQL Server support the following directives/options:
--      + MLDATA specifies that an inline XML-Data Reduced (XDR) schema should be returned.
--      + XMLSCHEMA is used to request an inline W3C XML Schema (XSD) built from result.
--      + ELEMENTS to format columns as subelements, this option is supported in RAW, AUTO, and PATH modes only.
--      + TYPE specify that the query returns the results as the xml type; if not specified, the XML data returned to client as a string type.
--      + ROOT[('RootName')] specify that a single, top-level element is added to the result, the default value is <root>.
--      + BINARY BASE64 tell the returned binary data is represented in base64-encoded format.
--      + XSINIL specifies that an element that has an xsi:nil attribute set to TRUE be created for NULL column values; this option can only be used with ELEMENTS directive.
--      + ABSENT is used with ELEMENTS directive by default, it specifies that no elements are created for NULL values.
--  + Directives are seperated by comma(,); each option must be used with directive
-- 9. OPENXML
--	+ Is a technique to parse in-memory XML documents into rowsets, similar to a table or a view.
--	+ It creates an in-memory document object model(DOM) tree representation of the XML document.
--	+ Used as a keyword that accepts some parameters and options:
--		+ An XML document handle (idoc): is a DOM tree representation of an XML document, execute procedure sp_xml_preparedocument to prepare the document, use procedure sp_xml_removedocument to free the memory
--		+ AN XPath expression: to identify the nodes to be mapped to row (rowpattern).
--		+ A description of the rowset to be generated.
--		+ Mapping between the rowset columns and the XML nodes.
--	+ There are some options to specify a rowset description/schema:
--		+ Use the edge table format: represents the fine-grained XML document structure, includes the element and attribute names, the document hierarchy, the namesaces, and the processing instructions.
--		+ Use the WITH clause to specify an existing table: instruct OPENXML to refers to the schema of an existing table to generate the rowset.
--		+ Use the WITH clasue to specify a schema: manually specify a complete schema, by defining column names, their data types, their mapping to the XML document with/without column pattern (ColPattern)
--	+ Map between the rowset columns and the XML nodes
--		+ In the OPENXML statement, use the flags parameter to explicitly specify the type of mapping:
--			+ Value 1 for attribute-centric mapping.
--			+ Value 2 for element-centric mapping.
--			+ Value 3 indicates both 1 and 2.
--			+ Value 8 means only unconsumed XML data should be added to the OverFlow column defined in the WITH clause.
--			+ Value 9 indicates both 1 and 8.
--			+ Value 10 indidates both 2 and 8.
--			+ By default the value 1 is used.
--		+ In the WITH clause, use the ColPattern parameter to flexibly specify the type of mapping; this will overwrites or enhances the default mapping indicated by the flags



-- PRACTICE
USE AdventureWorks2025
GO




-- Create XML Schema collections
CREATE XML SCHEMA COLLECTION XSD1 
	AS N'<?xml version="1.0" encoding="UTF-16"?>
    <xsd:schema targetNamespace="schema1" xmlns="schema1" xmlns:schema1="schema1"
        elementFormDefault="qualified"
        attributeFormDefault="unqualified"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema">

        <xsd:complexType name="BonusItem">
            <xsd:choice minOccurs="0" maxOccurs="unbounded">
                <xsd:element name="Item1">
                    <xsd:complexType>
                        <xsd:attribute name="id" type="xsd:string" use="required"/>
                        <xsd:attribute name="quantity" type="xsd:integer" use="optional"/>
                    </xsd:complexType>
                </xsd:element>
                <xsd:element name="Item2">
                    <xsd:complexType>
                        <xsd:attribute name="id" type="xsd:string" use="required"/>
                        <xsd:attribute name="quantity" type="xsd:integer" use="optional"/>
                    </xsd:complexType>
                </xsd:element>
                <xsd:element name="Item3">
                    <xsd:complexType>
                        <xsd:attribute name="id" type="xsd:string" use="required"/>
                        <xsd:attribute name="quantity" type="xsd:integer" use="optional"/>
                    </xsd:complexType>
                </xsd:element>
            </xsd:choice>
        </xsd:complexType>

        <xsd:complexType name="ProductType">
            <xsd:sequence>
                <xsd:element name="ProductName" type="xsd:string"/>
                <xsd:element name="Price" type="xsd:decimal"/>
                <xsd:element name="Quantity" type="xsd:integer"/>
                <xsd:element name="Category" type="xsd:string"/>
                <xsd:element name="Promotion" type="xsd:boolean"/>
                <xsd:element name="BonusItems" type="schema1:BonusItem"/>
            </xsd:sequence>
        </xsd:complexType>

        <xsd:simpleType name="PaymentType">
            <xsd:restriction base="xsd:string">
                <xsd:enumeration value="cash"/>
                <xsd:enumeration value="card"/>
            </xsd:restriction>
        </xsd:simpleType>

        <xsd:element name="root">
            <xsd:complexType>
                <xsd:sequence>
                    <xsd:element name="Order" minOccurs="0" maxOccurs="unbounded">
                        <xsd:complexType>
                            <xsd:sequence>
                                <xsd:element name="Product" type="schema1:ProductType" minOccurs="1" maxOccurs="unbounded"/>
                            </xsd:sequence>
                            <xsd:attribute name="OrderID" type="xsd:integer" use="required"/>
                            <xsd:attribute name="OrderDate" type="xsd:dateTime" use="optional"/>
                            <xsd:attribute name="TotalPrice" type="xsd:decimal" use="optional"/>
                            <xsd:attribute name="PaymentType" type="schema1:PaymentType" use="optional"/>
                        </xsd:complexType>
                    </xsd:element>
                </xsd:sequence>
                <xsd:attribute name="ImportID" type="xsd:string" use="required"/>
            </xsd:complexType>
        </xsd:element>
    </xsd:schema>';
GO

CREATE XML SCHEMA COLLECTION XSD2 
    AS N'<xsd:schema targetNamespace="schema2a" xmlns="schema2a" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <xsd:element name="Element1" type="xsd:string" />
    </xsd:schema>
    <xsd:schema targetNamespace="schema2b" xmlns="schema2b" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <xsd:element name="Element2" type="xsd:integer" />
    </xsd:schema>'
GO




-- Specify constraints for XML data type column
CREATE OR ALTER FUNCTION dbo.afCheckExists_CustomerID(@var XML)
RETURNS Bit
AS BEGIN
	IF @var.exist('/Customer/@CustomerID') = 1 AND @var.exist('/Customer/CustomerName') = 1
        RETURN 1;
    RETURN 0;
END;
GO




-- Declare XML data type variable/parameter/column (with/without XSD, XML constraints)
DECLARE @xml1 XML(DOCUMENT XSD2); 
GO

DECLARE @xml2 XML(CONTENT XSD2); 
GO

CREATE OR ALTER PROCEDURE [dbo].[ProcX] @xml XML(XSD2) AS;
GO

IF OBJECT_ID('dbo.XMLDemo', 'U') IS NOT NULL DROP TABLE dbo.XMLDemo
CREATE TABLE dbo.XMLDemo (
    ID Int Identity(1,1) NOT NULL PRIMARY KEY,
    Orders XML (DOCUMENT XSD1) NOT NULL DEFAULT CAST(N'<?xml version="1.0" encoding="UTF-16"?><root xmlns="schema1" ImportID="IMP001"></root>' AS XML),
    Customer XML CHECK(dbo.afCheckExists_CustomerID(Customer) = 1) NOT NULL DEFAULT CAST(N'<Customer CustomerID="0"><CustomerName></CustomerName></Customer>' AS XML) 
)
GO




-- Create primary/secondary XML indexes ON XML data type column
CREATE PRIMARY XML INDEX Idx_XMLDemo_Orders ON XMLDemo(Orders)
GO

CREATE XML INDEX Idx_XMLDemo_Orders_PATH ON XMLDemo(Orders)
USING XML INDEX Idx_XMLDemo_Orders
FOR PATH
GO

CREATE XML INDEX Idx_XMLDemo_Orders_VALUE ON XMLDemo(Orders)
USING XML INDEX Idx_XMLDemo_Orders
FOR VALUE
GO

CREATE XML INDEX Idx_XMLDemo_Orders_PROPERTY ON XMLDemo(Orders)
USING XML INDEX Idx_XMLDemo_Orders
FOR PROPERTY
GO




-- Instantiate XML data
DECLARE @xml1 XML(DOCUMENT XSD2); 
DECLARE @xml2 XML(CONTENT XSD2); 
SET @xml1 = CAST(N'<Element1 xmlns="schema2a">Content</Element1>' AS XML)
SET @xml2 = CAST(N'<Element1 xmlns="schema2a">Content</Element1><Element2 xmlns="schema2b">1</Element2>' AS XML)
GO

INSERT INTO dbo.XMLDemo(Orders, Customer)
VALUES(N'<?xml version="1.0" encoding="UTF-16"?>
    <root xmlns="schema1" xmlns:ns="schema1" ImportID="IMP001">
        <ns:Order OrderID="1" OrderDate="2026-03-29T09:30:00" TotalPrice="199.99" PaymentType="card">
            <Product>
                <ProductName>Wireless Mouse</ProductName>
                <Price>99.99</Price>
                <Quantity>2</Quantity>
                <Category>Electronics</Category>
                <Promotion>true</Promotion>
                <BonusItems>
                    <Item1 id="MOUSEPAD01" quantity="1"/>
                </BonusItems>
            </Product>
        </ns:Order>
        <ns:Order OrderID="2">
            <Product>
                <ProductName>Laptop</ProductName>
                <Price>170.00</Price>
                <Quantity>1</Quantity>
                <Category>Computers</Category>
                <Promotion>false</Promotion>
                <BonusItems />
            </Product>
            <Product>
                <ProductName>SmartPhone</ProductName>
                <Price>120.00</Price>
                <Quantity>1</Quantity>
                <Category>Phones</Category>
                <Promotion>false</Promotion>
                <BonusItems />
            </Product>
        </ns:Order>
    </root>',
    DEFAULT)
GO

SELECT DepartmentID, Name, GroupName, ModifiedDate 
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
	BULK 'D:\Projects\SQL-Projects\Notes\2. XML\SampleData1.txt',
	SINGLE_BLOB
) AS x
GO

SELECT CONVERT(XML, BulkColumn, 2) AS [xml data with DTD]
FROM OPENROWSET(
	BULK 'D:\Projects\SQL-Projects\Notes\2. XML\SampleData2.txt',
	SINGLE_BLOB
) AS x
GO




-- Get information about XML schemas and schema collections
SELECT 
    'Get namespaces of a collection' AS [content],
    XSC.name AS [collection name],
    XSN.name AS [schema name/namespace],
    NULL AS XSD
FROM sys.xml_schema_collections XSC
INNER JOIN sys.xml_schema_namespaces XSN ON XSN.xml_collection_id = XSC.xml_collection_id
WHERE XSC.name = 'XSD1'
UNION ALL
SELECT 
    N'Get contents of a collection',
    N'XSD1',
    NULL,
    XML_SCHEMA_NAMESPACE (N'dbo', N'XSD1')
UNION ALL
SELECT 
    N'Output a specified schema from an XML schema collection',
    N'XSD2',
    N'schema2b',
    XML_SCHEMA_NAMESPACE(N'dbo', N'XSD2', 'schema2b')
GO




-- Get information about XML indexes
SELECT 
	OBJECT_NAME(object_id) AS [table],
	name AS [index name],
	type_desc AS [index type]
FROM sys.indexes
WHERE [type] = 3
GO

SELECT 
	OBJECT_NAME(object_id) AS [table],
	name AS [index name],
	CASE
		WHEN secondary_type IS NULL THEN N'True'
		ELSE N'False'
	END AS [is primary xml index],
	CASE secondary_type
		WHEN 'P' THEN N'PATH'
		WHEN 'R' THEN N'PROPERTY'
		WHEN 'V' THEN N'VALUE'
		ELSE N''
	END AS [seconary index type]
FROM sys.xml_indexes;
GO




-- FOR XML
-- WITH NAMESPACE
WITH XMLNAMESPACES ('uri' AS ns1)
SELECT
	ProductID AS 'ns1:ProductID',
	Name AS 'ns1:Name',
	Color AS 'ns1:Color'
FROM Production.Product
WHERE ProductID IN (316, 317)
FOR XML RAW ('ns1:Prod'), ELEMENTS XSINIL, ROOT;
GO

SELECT ProductModelID, Name
FROM Production.ProductModel
WHERE ProductModelID IN (122, 119)
FOR XML RAW, XMLSCHEMA ('urn:extracted-schema'), ROOT('x');
GO

SELECT ProductPhotoID, ThumbNailPhoto
FROM Production.ProductPhoto
WHERE ProductPhotoID = 1
FOR XML RAW, BINARY BASE64;

-- RAW mode
SELECT (
    SELECT BusinessEntityID, FirstName, LastName
    FROM Person.Person
    FOR XML AUTO, TYPE
).query('/Person.Person[1]');
GO

DECLARE @x nvarchar(100) =
(
    SELECT 
        ID,
        Orders.query('
        declare namespace ns="schema1";
        //ns:Order') AS Orders,
        Customer
    FROM XMLDemo root
    FOR XML RAW, TYPE
).value('
    declare namespace ns="schema1";
    (/row/Orders/ns:Order[@OrderID="2"][1]/ns:Product[1]/ns:ProductName[1]/text())[1]', 
    'nvarchar(100)');
SELECT @x AS [Name of the first product of Order with OrderID = "2"];
GO

-- AUTO mode
SELECT 
	IndividualCustomer.CustomerID, 
	IndividualCustomer.Name,
	IndividualCustomer.NoOfOrders,
	SOH.SalesOrderID,
	SOD.SalesOrderDetailID,
	SOD.LineTotal,
	SOD.ProductID,
	SOD.OrderQty,
	P.Name
FROM (
	SELECT 
		C.CustomerID, 
		P.FirstName + ' ' + P.LastName AS Name,
		COUNT(*) AS NoOfOrders
	FROM Sales.Customer AS C
	INNER JOIN Person.Person AS P ON p.BusinessEntityID = C.PersonID
	INNER JOIN Sales.SalesOrderHeader SOH ON SOH.CustomerID = C.CustomerID
	WHERE C.CustomerID IN (29672, 29734)
	GROUP BY C.CustomerID, P.FirstName, P.LastName
) AS IndividualCustomer
INNER JOIN Sales.SalesOrderHeader SOH ON SOH.CustomerID = IndividualCustomer.CustomerID
INNER JOIN Sales.SalesOrderDetail AS SOD ON SOD.SalesOrderID = SOH.SalesOrderID
INNER JOIN Production.Product AS P ON P.ProductID = SOD.ProductID
ORDER BY IndividualCustomer.CustomerID, SOh.SalesOrderID
FOR XML AUTO, ROOT;
GO

-- Nested AUTO mode
SELECT XmlCol.query('<Root> { /* } </Root>')
FROM (
	SELECT 
		(
			SELECT 
				TOP 2 SalesOrderID, SalesPersonID, CustomerID,
				(
					SELECT TOP 3 SalesOrderID, ProductID, OrderQty, UnitPrice
					FROM Sales.SalesOrderDetail
					WHERE SalesOrderDetail.SalesOrderID = SalesOrderHeader.SalesOrderID
					FOR XML AUTO, TYPE
				)
			FROM Sales.SalesOrderHeader
			WHERE Sales.SalesOrderHeader.SalesOrderID = SalesOrder.SalesOrderID
			FOR XML AUTO, TYPE
		),
		(
			SELECT * FROM 
			(
				SELECT SP.BusinessEntityID, E.NationalIDNumber
				FROM Sales.SalesPerson SP
				INNER JOIN HumanResources.Employee E ON E.BusinessEntityID = SP.BusinessEntityID
			) AS SalesPerson
			WHERE SalesPerson.BusinessEntityID = SalesOrder.SalesPersonID
			FOR XML AUTO, TYPE
		)
	FROM (
		SELECT SOH.SalesOrderID, SOH.SalesPersonID
		FROM Sales.SalesOrderHeader SOH
		INNER JOIN Sales.SalesPerson SP ON SP.BusinessEntityID = SOH.SalesPersonID
	) AS SalesOrder
	WHERE SalesOrder.SalesOrderID IN (43669, 43670)
	ORDER BY SalesOrder.SalesOrderID
	FOR XML AUTO, TYPE
) AS T(XmlCol);
GO

-- PATH mode
SELECT 
	N'Columns without name' AS [content],
	CAST((
		SELECT 1, ', ', 2, ', ', 3, ', ', 4, ', ', 5, ', ', 6
		FOR XML PATH('')
	) AS XML) AS [XML PATH]
UNION ALL
SELECT
	N'Complex query',
	CAST((
		SELECT 
			ProductModelID AS '@ProductModelID',
			(
				SELECT ProductID AS 'data()'
				FROM Production.Product
				WHERE Production.Product.ProductModelID = Production.ProductModel.ProductModelID
				FOR XML PATH('')
			) AS '@ProductIDs',
			[Name] AS 'Nested1/Nested2/@Name',
			[Name] AS 'Nested1/Nested2/Name',
			Instructions.query(
				'declare namespace MI="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions";
				/MI:root/MI:Location
				') AS ManuWorkCenterInformation,
			Instructions.query(
				'declare namespace MI="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions";
				/MI:root/MI:Location[1]
				') -- query with no column name, same with wildcard character '*'
		FROM Production.ProductModel
		WHERE ProductModelID = 7
		FOR XML PATH, ELEMENTS XSINIL
	) AS XML)
UNION ALL
SELECT 
	N'Complex query',
	CAST((
		SELECT 
			P.BusinessEntityID AS '@PersonID',
			'Example of using node tests such as text(), comment(), processing-instruction()' AS 'comment()',
			'Some pi' AS 'processing-instruction(PI)',
			P.FirstName AS 'Name/First/text()',
			p.MiddleName AS 'Name/Middle',
			p.LastName AS 'Name/Last',
			ISNULL(P.FirstName + ' ', '') + ISNULL(P.MiddleName + ' ', ' ') + ISNULL(P.LastName, '') AS 'Fullname',
			A.AddressLine1 AS 'Address/AddressLine1',
			A.AddressLine2 AS 'Address/AddressLine2',
			A.City AS 'Address/City'
		FROM Person.Person P
		INNER JOIN Person.BusinessEntityAddress B ON B.BusinessEntityID = P.BusinessEntityID
		INNER JOIN Person.Address A ON A.AddressID = B.AddressID
		WHERE P.BusinessEntityID IN (1, 2)
		FOR XML PATH, ELEMENTS XSINIL
	) AS XML)
GO




-- XML Parse using OPENXML
CREATE OR ALTER PROCEDURE [dbo].[OPENXMLDemo1]
AS
BEGIN
	-- Create tables for later population using OPENXML.
	IF OBJECT_ID('[dbo].[CustomersDemo]', 'U') IS NOT NULL
		DROP TABLE [dbo].[CustomersDemo]
	IF OBJECT_ID('[dbo].[OrdersDemo]', 'U') IS NOT NULL
		DROP TABLE [dbo].[OrdersDemo]

	CREATE TABLE [dbo].[CustomersDemo] (CustomerID Varchar(20) PRIMARY KEY,
					ContactName Varchar(20),
					CompanyName Varchar(20));
	CREATE TABLE [dbo].[OrdersDemo] (CustomerID varchar(20), OrderDate Datetime);
	
	DECLARE @docHandle Int;
	DECLARE @xmlDocument Nvarchar(MAX); -- or xml type
	SET @xmlDocument = 
	N'<ROOT>
		<Customers CustomerID="XYZAA" ContactName="Joe" CompanyName="Company1">
			<Orders CustomerID="XYZAA" OrderDate="2026-03-31T00:00:00" />
			<Orders CustomerID="XYZAA" OrderDate="2026-03-30T00:00:00" />
		</Customers>
		<Customers CustomerID="XYZBB" ContactName="Steve" CompanyName="Company2">
			No Orders yet!
		</Customers>
	</ROOT>';

	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

	-- Use OPENXML to provide rowset consisting of customer data.
	INSERT [dbo].[CustomersDemo]
	SELECT * 
	FROM OPENXML(@docHandle, N'/ROOT/Customers')
	WITH Customers;

	-- Use OPENXML to provide rowset consisting of order data.
	INSERT [dbo].[OrdersDemo]
	SELECT *
	FROM OPENXML(@docHandle, N'//Orders')
	WITH Orders;

	-- Remove the internal representation of the XML document.
	EXEC sp_xml_removedocument @docHandle

	SELECT * FROM [dbo].[CustomersDemo]
	SELECT * FROM [dbo].[OrdersDemo]
END
GO

CREATE OR ALTER PROCEDURE [dbo].[OPENXMLDemo2]
AS
BEGIN
	DECLARE @XmlDocumentHandle Int;
	DECLARE @XmlDocument Nvarchar(1000);
	SET @XmlDocument =
		N'<ROOT>
			<Customer>
				<CustomerID>VINET</CustomerID>
				<ContactName>Paul Henriot</ContactName>
				<Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
					<OrderDetail ProductID="11">
						<Quantity>12</Quantity>
						<Product ProductName="Phone" />
					</OrderDetail>
					<OrderDetail ProductID="42">
						<Quantity>10</Quantity>
						<Product ProductName="Watch" />
					</OrderDetail>
					Customer was very satisfied
				</Order>
			</Customer>
			<Customer>
				<CustomerID>LILAS</CustomerID>
				<ContactName>Carlos Gonzalez</ContactName>
				<Order OrderID="10283" CustomerID="LILAS" EmployeeID="3" OrderDate="1996-08-16T00:00:00">
					<OrderDetail ProductID="72" TotalPayment="1000">
						<Quantity>3</Quantity>
						<Product ProductName="Laptop" />
					</OrderDetail>
					Happy Customer
				</Order>
			</Customer>
		</ROOT>';

	-- Create an internal representation of the XML document.
	EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @XmlDocument;

	-- Execute a SELECT statement using OPENXML rowset provider.
	SELECT *
	FROM OPENXML (@XmlDocumentHandle, '/ROOT/Customer/Order/OrderDetail', 3)
	WITH (CustomerID	Varchar(10) '../../CustomerID',
		  ContactName	Varchar(20)	'../../ContactName',
		  OrderID		Int			'../@OrderID',
		  OrderDate		Datetime	'../@OrderDate',
		  Comment		ntext		'../text()',
		  ProductID		Int,
		  Quantity		Int,
		  ProductName	Varchar(20)	'Product/@ProductName');

	-- Execute a SELECT statement using a rowpattern ending with an attribute
	SELECT *
	FROM OPENXML (@XmlDocumentHandle, '/ROOT/Customer/Order/OrderDetail/@ProductID')
	WITH (ProductID Int '.',
		  TotalPayment Decimal(19,4) '../@TotalPayment',
		  Quantity Int '../Quantity',
		  ProductName Varchar(20) '../Product/@ProductName');

	-- Execute a SELECT statement returns all the columns in the edge table.
	WITH CTE_Edge_Table AS (
		SELECT id, parentid, nodetype, localname, prefix, namespaceuri, datatype, prev, text
		FROM OPENXML (@XmlDocumentHandle, '/ROOT/Customer')
	)
	SELECT [text] AS [Edge table - Customer ID]
	FROM CTE_Edge_Table
	WHERE localname = '#text' AND parentid IN (SELECT id FROM CTE_Edge_Table WHERE localname = 'CustomerID' AND nodetype = 1);

	-- Execute a SELECT statement using XML data type in the WITH clause
	SELECT *
	FROM OPENXML (@XmlDocumentHandle, '/ROOT/Customer', 10)
	WITH (CustomerID	Varchar(10),
		  xmlCustomerID	XML 'CustomerID',
		  OverFlow XML '@mp:xmltext');

	EXEC sp_xml_removedocument @XmlDocumentHandle;
END
GO

EXEC [dbo].[OPENXMLDemo1]
GO

EXEC [dbo].[OPENXMLDemo2]
GO

select CAST('<binary>EjRWeJA=</binary>' AS XML).value('.', 'varbinary(max)')
select CAST('<binary>EjRWeJA=</binary>' AS XML).value('.', 'varchar(max)')

-- XML Modification
