
-- DBA War Chest 
-- Remove TempDB File
-- 2015-02-20 

-- If TempDB has been assigned with too many files this script will remove a desired file. 

USE [tempdb]
GO
DBCC SHRINKFILE('tempdev5', EMPTYFILE)
GO
ALTER DATABASE [tempdb] REMOVE FILE [tempdev5]
GO