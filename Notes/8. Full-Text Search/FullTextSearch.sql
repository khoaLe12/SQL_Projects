
-- Full-Text Search
-- 1. The feature that support for full-text queries agains character-based data.
-- 2. Full-Text Search is an optional component of SQL Server Database Engine, its only available only if the option is enabled.
-- 3. To add feature to an existing instance, run SQL Server Installation Center -> Installation -> add features to an existing installation.
-- 4. The full-text index support all character based data type, include binary data type that represent the text file.
-- 5. Full-text queries perform linguistic searches against text data based on the rules of a particular language.
-- 6. A table can be full-text indexed only if that table has a unique, single-column, non-nullable index; choose the smallest index (A 4-byte, integer-based index is optimal) is required since it reduces the resources required by search service.
-- 7. By default, the system stoplist are applied to every full-text index, it allows to create a custom stoplist and associate with specified full-text index.
-- 8. Updating a full-text index immediately after each change could be resource-intensive, consider scheduling manual change tracking updates.
-- 9. To reduce the number of full-text index fragments, do rebuild or reorganize the index.
-- 10. The query support searching with the following conditions (know as term):
--	+ simple: one or more specific words or phrases.
--	+ prefix: A word or a phrase where the words in text begin with
--		- if a phrase prefix is used, it will produce derivative words or inflected forms of each tokenized within phrase.
--	+ generation: Inflectional forms of a specific word.
--	+ proximity: A word or phrase close to another word or phrase
--	+ thesaurus: Synonymous forms of a specific word.
--	+ weighted: Words or phrases using weighted values.
-- 11. Comparing with LIKE search, Full-Text Search can work on both character patterns and formtted binary data, and also much faster.
-- 12. Full-Text Search architecture:
--	+ The SQL Server process (sqlserver.exe)
--		- Responsible for managing and processing all 
--		- SQL Server query processor: responsible for processing all received queries that compile and execute them; if the query includes full-text search query, it will cooperate with Full-Text Engine.
--		- Full-Text Engine:  compiles and executes full-text queries, may receive input from thesaurus and stoplist.
--		- Thesaurus files: contains synonyms of search term.
--		- Stoplist objects: contains a list of common words that aren't useful for the search.
--		- Full-text gatherer: works with the full-text crawl threads, responsible for scheduling and driving the population of full-text indexes.
--		- Index writer (indexer): build the structure that is used to store the index tokens.
--		- Filter daemon manager: responsible for monitoring the status of the Full-text Engine filter daemon host
--	+ The filter daemon host process (fdhost.exe)
--		- Running seperately under the FDHOST launcher service and started by the Full-Text Engine, the host is available only when the service account of this service is enable.
--		- Protocol handler: responsible for gathering data from memory, pass it to filter daemon host for further processing.
--		- Filters: filtering document data represented in binary format, extracts text and/or removes embedded formatting of documents in some extensions such as .doc, .xls, .xml., and pasrse it into text data.
--		- Word breakers and stemmers: constructs words from textual data with a language-specific stemmer component.
-- 13. Full-Text indexing process:
--	+ Firstly Full-Text Engine pushes large batches of data into memory and start the filter daemon host.
--	+ The host filters and word-breaks the data and converts it into word lists, each word also know as token, or keyword.
--	+ Optionaly perform extra processing to remove stopwords, and to normalize tokens.
--	+ For each text is processed, its tokens are stored in the full-text index or an index fragment.
--	+ When a population is complete, trigger a process that merges all index fragments together into one master full-text index.
-- 14. Full-Text querying process:
--	+ If a query include full-text query, its full-text portions are passed to the Full-Text Engine.
--	+ The Full-Text Engine performs word breaking and, optionally, thesaurus expansions, stemming, and stopword processing.
--	+ Convert the full-text query into SQL operators, primarily as stemming table-valued functions (STVFs).
--	+ During query execution, these STVFs search full-text indexes to find matching results.
-- 15. Full-text index structure:
--	+ Full-Text indexes can be stored in many fragments; only one master fragment persisted in a database is the optimal case for full-text search.
--	+ A fragment is an internal table that store inverted index data, each fragment has some infomative valuable columns:
--		- Keyword: contains a representation of a single token extracted at indexing time.
--		- ColId: id that corresponds to a particular column that is full-text indexed.
--		- DocId: the id of text data that keyword belong to.
--		- Occurence: the position number of keyword within the text data specified by DocId.
--	+ Each text data is associated with a unique documentId which reference to full-text indexed column data of a table's row.




-- PRACTICE
USE AdventureWorks2025;
GO


-- Verify if Full-Text Search is available
SELECT SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;


-- Create full-text catalog
CREATE FULLTEXT CATALOG AdvWksDocFTCat;
GO


-- Check accent-sensitivity property of a catalog
SELECT FULLTEXTCATALOGPROPERTY('AdvWksDocFTCat', 'AccentSensitivity') AS IsAccentSensitivity;
GO


-- Create a custom stoplist
CREATE FULLTEXT STOPLIST myStoplist FROM SYSTEM STOPLIST;
ALTER FULLTEXT STOPLIST myStoplist ADD 'and' LANGUAGE 'Spanish';
ALTER FULLTEXT STOPLIST myStoplist ADD 'and' LANGUAGE 'French';
GO


-- Create a unique, single-column, non-nullable index on a full-text indexed table
CREATE UNIQUE INDEX Idx_FT_Document_DocumentNode ON Production.Document(DocumentNode);
GO


-- Create full-text index on the column
CREATE FULLTEXT INDEX ON Production.Document 
(
	Document						-- Full-text index column name
		TYPE COLUMN FileExtension	-- Name of column that contains file type information
		Language 2057				-- 2057 is the LCID for British English
)
KEY INDEX Idx_FT_Document_DocumentNode ON AdvWksDocFTCat	-- Unique index
WITH CHANGE_TRACKING AUTO,									-- Population type
	 STOPLIST = myStoplist;									-- Stoplist that associated with
GO


-- Drop full-text index
DROP FULLTEXT INDEX ON Production.Document
GO


-- Rebuild/Reorganize index
ALTER FULLTEXT CATALOG AdvWksDocFTCat REBUILD WITH ACCENT_SENSITIVITY = ON;
ALTER FULLTEXT CATALOG AdvWksDocFTCat REORGANIZE;
GO





-- QUERY

-- Prepare full-text index for demo
CREATE UNIQUE INDEX Idx_FT_Product_ProductID ON Production.Product(ProductID);
CREATE FULLTEXT INDEX ON Production.Product 
(
	Name
		Language 2057
)
KEY INDEX Idx_FT_Product_ProductID ON AdvWksDocFTCat
WITH CHANGE_TRACKING AUTO;
GO

CREATE UNIQUE INDEX Idx_FT_ProductDescription_ProductDescriptionID ON Production.ProductDescription(ProductDescriptionID);
CREATE FULLTEXT INDEX ON Production.ProductDescription
(
	Description
		Language 2057
)
KEY INDEX Idx_FT_ProductDescription_ProductDescriptionID ON AdvWksDocFTCat
WITH CHANGE_TRACKING AUTO;
GO

CREATE UNIQUE INDEX Idx_FT_Address_AddressID ON Person.Address(AddressID);
CREATE FULLTEXT INDEX ON Person.Address
(
	AddressLine1
		Language 2057
)
KEY INDEX Idx_FT_Address_AddressID ON AdvWksDocFTCat
WITH CHANGE_TRACKING AUTO;
GO



-- Find products that contain the word "Mountain"
SELECT Name, ListPrice
FROM Production.Product
WHERE CONTAINS(Name, 'Mountain');
GO


-- Search for all documents that contain words related to "vital safety components"
SELECT Title
FROM Production.Document
WHERE FREETEXT (Document, 'vital safety components')


-- Query product description that contains the word "aluminum" near either the word "light" or the word "lightweight" with rank of 2 or higher.
SELECT 
	FT_TBL.ProductDescriptionID,
	FT_TBL.Description,
	KEY_TBL.Rank
FROM Production.ProductDescription AS FT_TBL 
INNER JOIN CONTAINSTABLE (
	Production.ProductDescription, 
	Description, 
	'(light NEAR aluminum) OR (lightweight NEAR aluminum)'
) AS KEY_TBL ON KEY_TBL.[KEY] = FT_TBL.ProductDescriptionID
WHERE KEY_TBL.RANK > 2
ORDER BY KEY_TBL.RANK DESC;
GO


-- Query product description that contains the word related to "perfect all-around bike" and rank them
SELECT 
	KEY_TBL.RANK,
	FT_TBL.Description
FROM Production.ProductDescription AS FT_TBL
INNER JOIN FREETEXTTABLE (
	Production.ProductDescription,
	Description,
	'perfect all-around bike'
) AS KEY_TBL ON KEY_TBL.[KEY] = FT_TBL.ProductDescriptionID
ORDER BY KEY_TBL.RANK DESC
GO


-- Search for product descriptions that contain any word whose spelling begin with the prefix "top"
SELECT Description, ProductDescriptionID
FROM Production.ProductDescription
WHERE CONTAINS (Description, '"top*"');
GO


-- Search for product descriptions that contain any inflectional form of "extract" followed by any word starting with "word".
-- Ex: the results could be "extract word", "extracts word", "extracting words", "extracted words"
SELECT Description, ProductDescriptionID
FROM Production.ProductDescription
WHERE CONTAINS (Description, '"extract word*"');
GO


-- Search for any form of the word "foot" (e.g. "foot", "feet", and so on) in the Comments column
SELECT Comments, ReviewerName
FROM Production.ProductReview
WHERE CONTAINS (Comments, 'FORMSOF(INFLECTIONAL, "foot")');
GO


-- Search for synonyms of the word "car" in the Comments column
SELECT Comments, ReviewerName
FROM Production.ProductReview
WHERE CONTAINS (Comments, 'FORMSOF(THESAURUS, "car")');
GO
SELECT Comments, ReviewerName
FROM Production.ProductReview
WHERE FREETEXT (Comments, 'car');
GO