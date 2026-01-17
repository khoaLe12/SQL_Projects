


-- 1. EXTENDED PROPERTY
-- They are metadata annotation can be attached to objects (table, columns, index, etc) 
-- to describe their purpose, usage, or constraints
-- EX: add description to column [Production].Product.ProductLine which lists all available values and
-- explains the meaning of each value
EXEC sp_addextendedproperty 
	@name='MS_Description',
	@value=N'R = Road, M = Mountain, T = Touring, S = Standard' , 
	@level0type=N'SCHEMA',
	@level0name=N'Production', 
	@level1type=N'TABLE',
	@level1name=N'Product', 
	@level2type=N'COLUMN',
	@level2name=N'ProductLine'
GO
;
SELECT 
	ep.name AS extended_property_name,
	OBJECT_NAME(c.object_id) AS [table],
	c.name AS [column],
	ep.value AS [description]
FROM sys.extended_properties ep
JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE c.name = 'ProductLine' AND OBJECT_NAME(c.object_id) = 'Product'



-- 2. XML SCHEMA DEFINITION
select 
	xsc.name,
	xsn.name,
	XML_SCHEMA_NAMESPACE(SCHEMA_NAME(xsc.schema_id), xsc.name) AS XSDDefinition
from sys.xml_schema_collections xsc
inner join sys.xml_schema_namespaces xsn ON xsn.xml_collection_id = xsc.xml_collection_id
where xsc.name = 'StoreSurveySchemaCollection'
	AND SCHEMA_NAME(xsc.schema_id) = 'Sales'
;



-- 3. Available timezone
select * from sys.time_zone_info