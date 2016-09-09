
-- DBA War Chest 
-- Gap Checker
-- 2016-08-30

-- Discover numeric gaps in a specific column in a specific table.

DECLARE @TableName SYSNAME,@ColumnName SYSNAME, @FromValue BIGINT , @ToValue BIGINT

-- Set column and table
SELECT	@TableName = 'TABLENAME', @ColumnName = 'COLUMN', 
-- Set range to search in for gaps
		@FromValue = 1, @ToValue = 1000000

DECLARE @Command VARCHAR(MAX)  

SET @Command = '
;WITH CTE
AS
(
	SELECT	' + QUOTENAME(@ColumnName) + ' AS SeqNo
	FROM	dbo.' + QUOTENAME(@TableName) + '
	WHERE	' + QUOTENAME(@ColumnName) + ' >= ' + CONVERT(VARCHAR(20),@FromValue) + '  
		AND ' + QUOTENAME(@ColumnName) + ' < ' + CONVERT(VARCHAR(20),@ToValue) + '
)

SELECT	StartSeqNo = SeqNo + 1, 
		EndSeqNo =	(
						SELECT MIN(B.SeqNo)
						FROM CTE  AS B
						WHERE B.SeqNo > A.SeqNo
					) - 1
FROM CTE AS A
WHERE NOT EXISTS	(
						SELECT *
						FROM CTE  AS B
						WHERE B.SeqNo = A.SeqNo + 1
					) 
	AND SeqNo <	(
					SELECT MAX(SeqNo) 
					FROM CTE  B 
				);';

EXEC sp_ExecuteSQL @Command

