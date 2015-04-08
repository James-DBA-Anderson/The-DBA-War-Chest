
-- DBA War Chest 
-- Backup History Removal Indexes
-- 2015-03-30

-- The following indexes dramatically speed up the removal of old records. 

USE MSDB;

--CREATE INDEX [media_set_id] ON [dbo].[backupset] ([media_set_id])
--CREATE INDEX [restore_history_id] ON [dbo].[restorefile] ([restore_history_id])
--CREATE INDEX [restore_history_id] ON [dbo].[restorefilegroup] ([restore_history_id])

-- View record counts on the backup history tables

SELECT COUNT(1) FROM restorefile
SELECT COUNT(1) FROM restorefilegroup
SELECT COUNT(1) FROM restorehistory
SELECT COUNT(1) FROM backupfile
SELECT COUNT(1) FROM backupset
SELECT COUNT(1) FROM backupmediafamily
SELECT COUNT(1) FROM backupmediaset

-- Remove records old then the date passed as a param.

--exec sp_delete_backuphistory '2015-01-01'