
-- DBA War Chest 
-- Table Sizes 
-- 2015-10-01

-- Return information about the size of each table in the current database

CREATE TABLE #temp 
(
	table_name		SYSNAME ,
	row_count		CHAR(10),
	reserved_size	VARCHAR(50),
	data_size		VARCHAR(50),
	index_size		VARCHAR(50),
	unused_size		VARCHAR(50)
)

SET NOCOUNT ON

INSERT #temp

EXEC sp_msforeachtable 'sp_spaceused ''?'''

SELECT		a.table_name,
			a.row_count,
			COUNT(1) AS col_count,
			CONVERT(INT, REPLACE(a.data_size, ' KB', '')/1024)/1024 AS DataSize_GB,
			CONVERT(INT, REPLACE(a.index_size, ' KB', '')/1024)/1024 IndexSize_GB

FROM		#temp a
INNER JOIN	information_schema.columns b ON a.table_name collate database_default = b.table_name collate database_default

GROUP BY	a.table_name
			, a.row_count
			, a.data_size
			, a.index_size

ORDER BY	CAST(REPLACE(a.data_size, ' KB', '') AS integer) DESC
			, a.row_count

DROP TABLE #temp
