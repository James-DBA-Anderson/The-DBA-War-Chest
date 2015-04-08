
-- DBA War Chest 
-- Backup History
-- 2015-03-30

-- Show detailed information on the last 300 backups on the current server.


USE MSDB;
GO

SELECT TOP	300
			bckset.database_name AS DatabaseName,
			bckmdiaset.physical_device_name AS BackupLocation,
			CASE 
				WHEN bckset.backup_size <= '10485760' THEN
					CAST(CAST(bckset.backup_size/1024 AS INT) AS VARCHAR(14)) + ' ' + 'KB'
				ELSE
					CASE 
						WHEN bckset.backup_size <= '1048576000' THEN
							CAST(CAST(bckset.backup_size/1024/1024 AS INT) AS VARCHAR(14)) + ' ' + 'MB'
						ELSE
							CAST(CAST(bckset.backup_size/1024/1024/1024 AS INT) AS VARCHAR(14)) + ' ' + 'GB'
					END
			END backupSize,
			CAST (bckset.backup_start_date AS smalldatetime) AS StartTime,
			CAST (bckset.backup_finish_date AS smalldatetime)FinishTime,
			CASE 
				WHEN CAST(DATEDIFF(second, bckset.backup_start_date, bckset.backup_finish_date )AS VARCHAR (4)) <= 60 THEN
					CAST(DATEDIFF(second, bckset.backup_start_date,bckset.backup_finish_date) AS VARCHAR(4))+ ' ' + 'Seconds'
				ELSE
					CAST(DATEDIFF(minute, bckset.backup_start_date,bckset.backup_finish_date) AS VARCHAR(4))+ ' ' + 'Minutes'
			END AS TimeTaken,
			CAST(bckset.first_lsn AS VARCHAR(25)) AS FirstLogSequenceNumber,
			CAST(bckset.last_lsn AS VARCHAR(25)) AS LastLogSequenceNumber,
			CASE bckset.[type]
				WHEN 'D' THEN 'Full'
				WHEN 'I' THEN 'Differential database'
				WHEN 'L' THEN 'Transaction Log'
				WHEN 'F' THEN 'File or filegroup'
				WHEN 'G' THEN 'Differential file'
				WHEN 'P' THEN 'Partial'
				WHEN 'Q' THEN 'Differential partial'
			END AS BackupType,
			bckset.server_name As ServerName,
			bckset.recovery_model As RecoveryModel,
			CASE bckset.is_snapshot
				WHEN '0' THEN 'FALSE'
				WHEN '1' THEN 'TRUE'
			END AS IsSnapshot,
			CASE [compatibility_level]
				WHEN 60 THEN 'SQL Server 6.0'
				WHEN 65 THEN 'SQL Server 6.5'
				WHEN 70 THEN 'SQL Server 7.0'
				WHEN 80 THEN 'SQL Server 2000'
				WHEN 90 THEN 'SQL Server 2005'
				WHEN 100 THEN 'SQL Server 2008'
				WHEN 110 THEN 'SQL Server 2012'
				WHEN 120 THEN 'SQL Server 2014'
			END AS CompatibilityLevel

FROM		msdb.dbo.backupset bckset
INNER JOIN	msdb.dbo.backupmediafamily bckmdiaset ON bckset.media_set_id = bckmdiaset.media_set_id

---WHERE bckset.database_name = ''

ORDER BY	backup_start_date DESC, backup_finish_date


