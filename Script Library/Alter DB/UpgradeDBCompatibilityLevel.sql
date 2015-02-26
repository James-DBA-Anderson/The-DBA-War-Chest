
-- DBA War Chest 
-- Upgrade DB 
-- 2015-02-20 

-- Uprgade a DB's compatibility level and rebuild the statistics after.

DECLARE @DB NVARCHAR(100), @level NVARCHAR(5)

-- Select DB to upgrade and level to upgrade to ---------

SET @DB = ''
SET @level = '' -- 100 = 2008, 110 = 2012, 120 = 2014

-----------------------------------------------------------
	
DECLARE @SQL NVARCHAR(MAX), @DBName NVARCHAR(MAX)

DECLARE @DBs TABLE
(DBName NVARCHAR(100))

INSERT INTO @DBs
SELECT [name] 
FROM sys.databases 
WHERE database_id > 4 
AND compatibility_level <> @level 
AND [name] = @DB
	
WHILE EXISTS(SELECT * FROM @DBs)
BEGIN	
	SELECT TOP 1 @DBName = DBName FROM @DBs

	SET @SQL =	'ALTER DATABASE [' + @DBName + '] SET COMPATIBILITY_LEVEL = 110;
				USE [' + @DBName + ']  
				DECLARE @SQL NVARCHAR(MAX) = N'''';

				Declare @Tables table
				([Schema] nvarchar(50)
				,[TableName] nvarchar(100))

				Insert into @Tables
				Select QUOTENAME(SCHEMA_NAME(schema_id)),QUOTENAME(name) 
				FROM sys.tables;

				Declare @Schema nvarchar(50), @TableName nvarchar(100)

				While Exists(Select * From @Tables)
				Begin
					Select Top 1 @Schema = [Schema], @TableName = [TableName] From @Tables
					Set @SQL = ''UPDATE STATISTICS '' + @Schema + ''.'' + @TableName + '' WITH FULLSCAN;''

					Begin Try
						EXEC SP_ExecuteSql @SQLToExecute = @SQL	
						Print ''Completed: '' + @SQL
					End Try
					Begin Catch
						DECLARE @ErrMsg nvarchar(4000)
						SELECT	@ErrMsg = SubString(ERROR_MESSAGE(),0,900)

						Select GetDate(), ''Failed updating stats on '' + @Schema + '' '' + @TableName + ''. Error: '' + @ErrMsg
					End Catch

					Delete From @Tables Where [Schema] = @Schema and [TableName] = @TableName 
				End'
	BEGIN TRY					
		EXEC sp_executesql @SQL
		PRINT 'Upgraded ' + @DBName
	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = SubString(ERROR_MESSAGE(),0,900)				
	END CATCH	
	
	DELETE FROM @DBs WHERE DBName = @DBName
END
