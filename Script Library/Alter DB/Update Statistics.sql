
-- DBA War Chest 
-- Update Statistics 
-- 2015-02-20 

-- Update statistics with a sample rate based on the amount of rows in each table


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT	ss.name AS SchemaNAme
		,st.name AS TableName
		,si.name AS IndexName
		,ssi.rowcnt

INTO	#IndexUsage
FROM	sys.indexes si
JOIN	sys.sysindexes ssi ON si.object_id = ssi.id AND si.name = ssi.name
JOIN	sys.tables st ON st.[object_id] = si.[object_id]
JOIN	sys.schemas ss ON ss.[schema_id] = st.[schema_id]

WHERE	st.is_ms_shipped = 0
		AND si.index_id != 0
		AND ssi.rowcnt > 100
		AND ssi.rowmodctr > 0

DECLARE @UpdateStatisticsSQL NVARCHAR(MAX)
SET @UpdateStatisticsSQL = ''

SELECT	@UpdateStatisticsSQL = @UpdateStatisticsSQL
			+ CHAR(10) + 'UPDATE STATISTICS '
			+ QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName)
			+ ' ' + QUOTENAME(IndexName) + ' WITH SAMPLE '
			+	CASE	
						WHEN rowcnt < 500000 THEN '100 PERCENT'
						WHEN rowcnt < 1000000 THEN '50 PERCENT'
						WHEN rowcnt < 5000000 THEN '25 PERCENT'
						WHEN rowcnt < 10000000 THEN '10 PERCENT'
						WHEN rowcnt < 50000000 THEN '2 PERCENT'
						WHEN rowcnt < 100000000 THEN '1 PERCENT'
						ELSE '3000000 ROWS'
				END
				+ '-- ' + CAST(rowcnt AS VARCHAR(22)) + ' rows'
FROM	#IndexUsage

DECLARE @StartOffset INT, @Length INT

SELECT @StartOffset = 0, @Length = 4000

WHILE (@StartOffset < LEN(@UpdateStatisticsSQL))
BEGIN
	PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length)
	SET @StartOffset = @StartOffset + @Length
END
PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length)

EXECUTE sp_executesql @UpdateStatisticsSQL

DROP TABLE #IndexUsage