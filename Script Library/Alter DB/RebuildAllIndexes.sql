
-- DBA War Chest 
-- Rebuild All Indexes 
-- 2015-02-20 

-- Rebuild every index in the the selected database with a fill factor of 100. 
-- This will get the databases indexes and statistics in the best possible shape but
-- it pays no attention to the fact that the index may not require rebuilding

DECLARE @Database NVARCHAR(100), @SQL NVARCHAR(MAX), @DatabaseId INT, @IndexName NVARCHAR(100), @SchemaName NVARCHAR(100), @TableName NVARCHAR(100)

-- Set database to run index rebuilds on ---------------
SET @Database = ''
--------------------------------------------------------

DECLARE @Indexes TABLE
(SchemaName NVARCHAR(100)
,TableName NVARCHAR(100)
,IndexName NVARCHAR(100))

SET @SQL = '
			Select 
					s.name As [Schema],
					t.name AS TableName,
					ind.name AS IndexName

			From	[' + @Database + '].sys.dm_db_index_physical_stats(DB_ID(''' + @Database + '''), NULL, NULL, NULL, NULL) indexstats
			JOIN	[' + @Database + '].sys.indexes ind ON ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id
			JOIN	[' + @Database + '].sys.tables t on ind.object_id = t.object_id
			JOIN	[' + @Database + '].sys.schemas s on t.schema_id = s.schema_id

			WHERE	indexstats.index_type_desc <> ''HEAP'' '

INSERT INTO @Indexes
EXEC SP_ExecuteSql @SQLToExecute = @SQL

WHILE EXISTS(SELECT * FROM @Indexes)
BEGIN
	BEGIN TRY
		SELECT TOP 1 @IndexName = IndexName, @SchemaName = SchemaName, @TableName = TableName FROM @Indexes
	
		SET @SQL = 'USE [' + @Database + '] 
					ALTER INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + '] REBUILD WITH (FILLFACTOR = 100);'

		EXEC SP_ExecuteSql @SQLToExecute = @SQL
		PRINT 'Rebuilt ' + @IndexName
	END TRY
	BEGIN CATCH
		SELECT @SQL
		SELECT 'Failed to rebuild index: ' + @IndexName + ' on ' + @TableName + '. ' + ERROR_MESSAGE()
	END CATCH

	DELETE FROM @Indexes WHERE @IndexName = IndexName AND @SchemaName = SchemaName AND @TableName = TableName
END