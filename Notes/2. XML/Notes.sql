

-- XML DATA
-- 1. SQL Server provides a powerful platform to work with XML
--	+ XML data can be stored natively in an xml data type column
--	+ XML data can be typed according to a collection of XML schemas, or left untyped.
--	+ Support querying XML data through XQuery.
--	+ Enhancements to OPENROWSET to allow bulk loading of XML data.
--	+ The ability to parse between relational data and XML data
--	+ XML columns can be compressed and indexed.
-- 2. Adventages of using XML data
--	+ The structure is effecient for fine-grained query like extracting some of the sections of within XML document.
--	+ Effectively modifying/inserting new sections without replacing whole document, performed in a transacted way.
--	+ Preserve the document order, and elements and attributes values.
-- 3. XML storage options:
--	+ Native storage as xml data type: 