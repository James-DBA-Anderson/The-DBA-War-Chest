
-- DBA War Chest 
-- VLF - Fix high counts 
-- 2015-09-29 

-- Attempt to fix high levels of VLFs in the transaction log by shrinking and then growing out to current size in chunks.
-- This script does not alter the auto growth amount as this should be decided on by the DBA and set accordingly.

-- @ChunkSize = Size in MB of chunks to grow the log file back out to its original size by. 
-- DO NOT USE A VALUE OF 4000 for @ChunkSize on SQL Server 2008R2 or lower because there is a bug.

USE <database-name>;

DECLARE @ChunkSize INT = 8000, 
		@file_name sysname,
		@file_size int,
		@file_growth int,
		@shrink_command nvarchar(max),
		@alter_command nvarchar(max)


SELECT	@file_name = name,
		@file_size = size

FROM	sys.database_files
WHERE	type_desc = 'log'

SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0, TRUNCATEONLY)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command

SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command

DECLARE @i INT = 1, 
		@Chunks INT = ROUND((((@file_size * 8) / 1024.0) / 8000), 0) -- Get number of 8GB size chunks that will fit into the log file.

WHILE @i <= @Chunks
BEGIN
	BEGIN TRY
		SELECT @alter_command = 'ALTER DATABASE [' + db_name() + '] MODIFY FILE (NAME = N''' + @file_name + ''', SIZE = ' + CONVERT(VARCHAR(10), (@ChunkSize * @i)) + ' MB)'
		PRINT @alter_command
		EXEC sp_executesql @alter_command
	END TRY
	BEGIN CATCH
		SELECT 'Error: ' + @file_name + ' ' + ERROR_MESSAGE()
	END CATCH
	SET @i = @i + 1
END