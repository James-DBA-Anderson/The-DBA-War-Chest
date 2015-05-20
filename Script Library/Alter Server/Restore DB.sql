
-- DBA War Chest 
-- Restore Database
-- 2015-04-23

-- Restore a database with the desired options

USE [master]

RESTORE DATABASE [NameOfDataBaseAfterRestore] 
FROM DISK = N'PathtoBavkupFile' 
WITH  FILE = 2,  
MOVE N'DataFileLogicalName' -- Think it's the logical name? 
TO N'NewPathForDataFile',  
MOVE N'LogFileLogicalName' 
TO N'NewPathForLogFile',  

NORECOVERY,  NOUNLOAD,  STATS = 5

GO


