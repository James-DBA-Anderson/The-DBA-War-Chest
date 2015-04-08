
-- DBA War Chest 
-- VLF - Fix high counts 
-- 2015-03-13 

-- Attempt to fix high levels of VLFs in the transaction log by shrinking and then growing out to current size.
-- This script does not alter the auto growth amount as this should be decided on by the DBA and set accordingly.

-- Make sure you have ran a transaction log backup before running this script to free up the VLFs you want to remove.

-- This script was written by David Levy. More info here: http://adventuresinsql.com/2009/12/a-busyaccidental-dbas-guide-to-managing-vlfs/

USE <database-name>;

DECLARE @file_name sysname,
 @file_size int,
 @file_growth int,
 @shrink_command nvarchar(max),
 @alter_command nvarchar(max)

SELECT @file_name = name,
 @file_size = (size / 128)
FROM sys.database_files
WHERE type_desc = 'log'

SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0, TRUNCATEONLY)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command

SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command

SELECT @alter_command = 'ALTER DATABASE [' + db_name() + '] MODIFY FILE (NAME = N''' + @file_name + ''', SIZE = ' + CAST(@file_size AS nvarchar) + 'MB)'
PRINT @alter_command
EXEC sp_executesql @alter_command