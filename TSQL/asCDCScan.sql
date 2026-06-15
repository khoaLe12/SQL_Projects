CREATE OR ALTER PROCEDURE [dbo].[asCDCScan]
	@pRet Int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @timestamp datetime = GETDATE()
		DECLARE @read_count Int = 0

		-- 1. Identify min max lsn to scan
		DECLARE @start_lsn Binary(10) = (
			SELECT TOP 1 lsn_end
			FROM [dbo].[sysCdcScanHistory]
			ORDER BY lsn_end DESC
		)
		DECLARE @end_lsn Binary(10) = sys.fn_cdc_get_max_lsn()

		-- 2. Validate lsn values
		IF @start_lsn = @end_lsn
		BEGIN
			ROLLBACK TRANSACTION;
			SET @pRet = 0;
			RETURN;
		END
		ELSE IF @start_lsn IS NOT NULL
		BEGIN
			SET @start_lsn = sys.fn_cdc_map_time_to_lsn('smallest greater than', sys.fn_cdc_map_lsn_to_time(@start_lsn));
		END

		-- 3. Scan each tables
		IF OBJECT_ID('tempdb..#tKeys') IS NOT NULL 
			DROP TABLE #tKeys
		CREATE TABLE #tKeys(column_name Nvarchar(50))

		IF OBJECT_ID('tempdb..#tColumns') IS NOT NULL 
			DROP TABLE #tColumns
		CREATE TABLE #tColumns(column_name Nvarchar(50), c_name Nvarchar(50), cast_column_name Nvarchar(100), cast_next_column_name Nvarchar(150), ordinal CHAR(5))
		
		DECLARE @table_name Nvarchar(128),
				@cdc_table Nvarchar(128),
				@cdc_query Nvarchar(255),
				@extract_next Nvarchar(MAX),
				@gen_data_key Nvarchar(MAX),
				@gen_data_origin Nvarchar(MAX),
				@gen_data_target2 Nvarchar(MAX),
				@gen_data_target3 Nvarchar(MAX),
				@gen_data_change Nvarchar(MAX),
				@sql Nvarchar(MAX),
				@paramDefinition NVARCHAR(200);
		DECLARE csTable CURSOR LOCAL FAST_FORWARD FOR SELECT table_name FROM [dbo].[sysCDCEnableTable] WHERE cdc_enabled = 1;
	
		OPEN csTable;
		FETCH NEXT FROM csTable INTO @table_name

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Get columns information
			SET @cdc_table = REPLACE(@table_name, '.', '_');
			TRUNCATE TABLE #tKeys;
			TRUNCATE TABLE #tColumns;

			INSERT INTO #tKeys
			SELECT c.name
			FROM sys.indexes idx
			INNER JOIN sys.index_columns idxc ON idxc.object_id = idx.object_id AND idxc.index_id = idx.index_id
			INNER JOIN sys.columns c ON c.object_id = idxc.object_id AND c.column_id = idxc.column_id
			WHERE idx.object_id = OBJECT_ID(@table_name) AND idx.is_primary_key = 1;
			
			WITH CTE_Type_Convert AS (
				SELECT
					CASE 
						WHEN name IN ('geometry', 'geography') THEN N'n1.STAsText()'
						WHEN name IN ('hierarchyid') THEN N'n1.ToString()'
						WHEN name IN ('xml', 'text', 'ntext') THEN N'CAST(n1 AS Nvarchar(MAX))'
						WHEN name IN ('image') THEN N'CAST(n1 AS Varbinary(MAX))'
					END AS type_convert,
					system_type_id,
					user_type_id
				FROM sys.types
				WHERE name IN ('geometry', 'geography', 'hierarchyid', 'xml', 'text', 'ntext', 'image')
			)
			INSERT INTO #tColumns (column_name, c_name, cast_column_name, cast_next_column_name, ordinal)
			SELECT 
				CASE 
					WHEN tc.type_convert IS NOT NULL THEN NULL
					ELSE c.name
				END AS column_name,
				c.name AS c_name,
				CASE 
					WHEN tc.type_convert IS NOT NULL THEN REPLACE(tc.type_convert, 'n1', c.name) + ' AS ' + c.name
					ELSE NULL
				END AS cast_column_name,
				CASE 
					WHEN tc.type_convert IS NOT NULL THEN REPLACE(tc.type_convert, 'n1', N'Next_' + c.name)  + ' AS ' + c.name
					ELSE NULL
				END AS cast_next_column_name,
				CAST(sys.fn_cdc_get_column_ordinal(@cdc_table, c.name) AS CHAR) AS ordinal
			FROM sys.columns c
			LEFT JOIN CTE_Type_Convert tc ON tc.system_type_id = c.system_type_id AND tc.user_type_id = c.user_type_id
			WHERE c.object_id = OBJECT_ID(@table_name)

			-- Generate raw sql string
			SET @cdc_query = N'cdc.fn_cdc_get_all_changes_' + REPLACE(@table_name, '.', '_');

			SELECT
				@extract_next = N'' + CHAR(10) + '						' + STRING_AGG('LEAD(' + ISNULL(column_name, c_name) + ') OVER (PARTITION BY __$seqval ORDER BY __$operation ASC) AS Next_' + ISNULL(column_name, c_name), ',' + CHAR(10) + '						'),
				@gen_data_origin = N'(SELECT ' + STRING_AGG(ISNULL(column_name, cast_column_name), ', ') + ' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)',
				@gen_data_target2 = N'(SELECT ' + STRING_AGG(ISNULL(column_name, cast_column_name), ', ') + ' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)',
				@gen_data_target3 = N'(SELECT ' + STRING_AGG(ISNULL('Next_' + column_name + ' AS ' + column_name, cast_next_column_name), ', ') + ' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)',
				@gen_data_change = N'(' + CHAR(10) + '								SELECT ' + CHAR(10) + STRING_AGG('									CASE sys.fn_cdc_is_bit_set(' + TRIM(ordinal) + ', __$update_mask) WHEN 1 THEN Next_' + column_name + ' ELSE NULL END AS ' + column_name, ',' + CHAR(10)) + CHAR(10) + '								FOR JSON PATH, WITHOUT_ARRAY_WRAPPER' + CHAR(10) + '								)'
			FROM #tColumns;

			SELECT 
				@gen_data_key = N'(SELECT ' + STRING_AGG(column_name, ', ') + ' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)' 
			FROM #tKeys;

			SET @sql = N'
				WITH CTE_Extract AS (
					SELECT 
						*, ' + @extract_next + '
					FROM ' + @cdc_query + '(' + CASE WHEN @start_lsn IS NULL THEN 'sys.fn_cdc_get_min_lsn(''' + REPLACE(@table_name, '.', '_') + ''')' ELSE '@start_lsn' END + ', @end_lsn, ''all update old'')
				),
				CTE_Transform AS (
					SELECT 
						@table_name AS data_table,
						' + @gen_data_key + ' AS data_key,
						CASE __$operation
							WHEN 2 THEN ''''
							WHEN 4 THEN ''''
							ELSE ' + @gen_data_origin + '
						END AS data_original,
						CASE __$operation
							WHEN 1 THEN ''''
							WHEN 4 THEN ''''
							WHEN 2 THEN ' + @gen_data_target2 + '
							WHEN 3 THEN ' + @gen_data_target3 + '
						END AS data_target,
						CASE __$operation
							WHEN 3 THEN ' + @gen_data_change + '
							ELSE ''''
						END AS data_change,
						CASE __$operation
							WHEN 1 THEN N''On Delete''
							WHEN 2 THEN N''On Insert''
							WHEN 3 THEN N''On Update''
						END AS action_content,
						CASE __$operation
							WHEN 1 THEN N''DELETE''
							WHEN 2 THEN N''INSERT''
							WHEN 3 THEN N''UPDATE''
						END AS action_code,
						__$start_lsn AS lsn,
						__$operation as operation
					FROM CTE_Extract
				)
				INSERT INTO dbo.sysCDCDataChanges (
					data_table, 
					data_key, 
					data_original, 
					data_target,
					data_change,
					action_content,
					action_code,
					lsn
				)
				SELECT
					data_table,
					data_key, 
					data_original, 
					data_target,
					data_change,
					action_content,
					action_code,
					lsn
				FROM CTE_Transform
				WHERE operation <> 4';

			SET @paramDefinition = N'@start_lsn Binary(10), @end_lsn Binary(10), @table_name Nvarchar(128)';
			--print @sql
			EXEC sp_executesql
				@sql,
				@paramDefinition,
				@start_lsn = @start_lsn,
				@end_lsn = @end_lsn,
				@table_name = @table_name;

			SET @read_count = @read_count + @@ROWCOUNT;

			FETCH NEXT FROM csTable INTO @table_name
		END

		CLOSE csTable;
		DEALLOCATE csTable;

		IF @start_lsn IS NULL
			SET @start_lsn = sys.fn_cdc_map_time_to_lsn('smallest greater than', '1900-01-01')

		INSERT INTO [dbo].[sysCdcScanHistory] (
			lsn_start,
			lsn_end,
			[timestamp],
			duration_sec,
			read_count
		)
		VALUES (
			@start_lsn,
			@end_lsn,
			@timestamp,
			CAST(ABS(DATEDIFF(MILLISECOND, @timestamp, GETDATE())) AS DECIMAL) / 1000,
			@read_count
		)

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
		PRINT 'Error Message: ' + ERROR_MESSAGE();

		THROW; 
	END CATCH

	IF OBJECT_ID('tempdb..#tKeys') IS NOT NULL 
			DROP TABLE #tKeys
	IF OBJECT_ID('tempdb..#tColumns') IS NOT NULL 
		DROP TABLE #tColumns

	SET @pRet = @@ERROR

	SET NOCOUNT OFF;
END
