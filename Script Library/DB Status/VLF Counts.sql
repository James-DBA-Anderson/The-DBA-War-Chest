
-- DBA War Chest 
-- VLF counts 
-- 2015-03-13 

-- Display all VLF counts for DBs in the current instance 

DECLARE @SQL NVARCHAR(1000), @DBName NVARCHAR(128), @Count INT

IF OBJECT_ID('tempdb..#DBs') IS NOT NULL
	DROP TABLE #DBs

CREATE TABLE #DBs
(
	DBName	NVARCHAR(128)
)

INSERT INTO #DBs
SELECT name
FROM master.dbo.sysdatabases

IF OBJECT_ID('tempdb..#LogInfo') IS NOT NULL
	DROP TABLE #LogInfo

CREATE TABLE #LogInfo
(
	DBName NVARCHAR(128),
	VLF_Count INT
)

IF OBJECT_ID('tempdb..#LogDetails') IS NOT NULL
	DROP TABLE #LogDetails

CREATE TABLE #LogDetails
(
	RecoveryUnitId	TINYINT,
	FileID			TINYINT,
	FileSize		BIGINT,
	StartOffset		BIGINT,
	FSeqNo			INT,
	[Status]		TINYINT,
	Parity			TINYINT,
	CreateLSN		NUMERIC(25,0)
)

WHILE EXISTS(SELECT 1 FROM #DBs)
BEGIN
	BEGIN TRY
		SELECT TOP 1 @DBName = DBName FROM #DBs 

		SET @SQL = 'DBCC loginfo (' + '''' + @DBName + ''') '

		INSERT INTO #LogDetails
		EXEC (@SQL)		

		SET @Count = @@rowcount

		INSERT INTO	#LogInfo
		SELECT	@DBName, @Count
	END TRY
	BEGIN CATCH
		PRINT N'Failed discovering VLF count for ' + @DBName + ': ' + Error_Message()
	END CATCH

	DELETE FROM #DBs WHERE DBName = @DBName
	TRUNCATE TABLE #LogDetails
END


SELECT	DBName
		,VLF_Count

FROM	#LogInfo

ORDER BY DBName


DROP TABLE #LogDetails
DROP TABLE #LogInfo
DROP TABLE #DBs
