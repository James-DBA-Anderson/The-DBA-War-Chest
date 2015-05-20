
-- DBA War Chest 
-- Restore Database
-- 2015-04-23

-- Restore a transaction log backup to a database with the desired options

RESTORE LOG [DatabaseToRestoreLogAgainst] 
FROM  DISK = N'PathToLogBackup' 
WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10
GO