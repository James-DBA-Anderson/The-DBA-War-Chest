
-- DBA War Chest 
-- Restore History
-- 2015-06-08

-- Show detailed information on RESTORE operations.

SELECT		DatabaseRestoredTo = RH.destination_database_name,
			TimeOfRestore = RH.restore_date,
			UserImplimentingRestore = RH.user_name,
			CASE RH.restore_type 
				WHEN 'D' THEN 'Full DB Restore'
				WHEN 'F' THEN 'File Restore'
				WHEN 'G' THEN 'Filegroup Restore'
				WHEN 'I' THEN 'Differential Restore'
				WHEN 'L' THEN 'Log Restore'
				WHEN 'V' THEN 'Verify Only'
			END AS RestoreType,
			ServerWhereBackupTaken = BS.server_name,
			UserWhoBackedUpTheDatabase = BS.user_name,
			BackupOfDatabase = BS.database_name,
			DateOfBackup = BS.backup_start_date,
			RestoredFromPath = BMF.physical_device_name	

FROM		msdb.dbo.restorehistory RH
INNER JOIN	msdb.dbo.backupset BS ON RH.backup_set_id = BS.backup_set_id
INNER JOIN	msdb.dbo.backupmediafamily BMF ON BS.media_set_id = BMF.media_set_id 

--WHERE RH.restore_date > DATEADD(DAY, -7, GETDATE())

ORDER BY	RH.restore_history_id DESC
