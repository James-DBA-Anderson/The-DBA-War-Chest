
--TODO: Think of a good way to replace the paths so they match the detination server.
--		Also make into two separate scripts as the restore function needs the .bak files to exist

DECLARE @SQL NVARCHAR(MAX) = '', @Database NVARCHAR(256), @BackupSegment NVARCHAR(2048)

DECLARE @BackupFiles TABLE
(FileNameAndPath NVARCHAR(MAX)
,Processed BIT)

-- Set variables -----------------------
USE OLL_Morrisons_Migrated

SELECT @Database = DB_NAME() -- Use current database

INSERT INTO @BackupFiles
SELECT 'P:\Logshipping\Logs\OLL_Morrisons_Migrated_1.bak', 0
UNION
SELECT 'P:\Logshipping\Logs\OLL_Morrisons_Migrated_2.bak', 0
UNION
SELECT 'P:\Logshipping\Logs\OLL_Morrisons_Migrated_3.bak', 0
UNION
SELECT 'P:\Logshipping\Logs\OLL_Morrisons_Migrated_4.bak', 0
----------------------------------------

SET @SQL = 'BACKUP DATABASE [' + @Database + ']
'

DECLARE @FileGroups TABLE
(BackupSegment NVARCHAR(2048)
,Processed BIT)

DECLARE @Files TABLE
([LogicalName]			NVARCHAR(128),
[PhysicalName]			NVARCHAR(260),
[Type]					CHAR(1),
[FileGroupName]			NVARCHAR(128),
[Size]					NUMERIC(20,0),
[MaxSize]				NUMERIC(20,0),
[FileId]				BIGINT,
[CreateLSN]				NUMERIC(25,0),
[DropLSN]				NUMERIC(25,0),
[UniqueId]				UNIQUEIDENTIFIER,
[ReadOnlyLSN]			NUMERIC(25,0),
[ReadWriteLSN]			NUMERIC(25,0),
[BackupSizeInBytes]		BIGINT,
[SourceBlockSize]		INT,
[FileGroupId]			INT,
[LogGroupGUID]			UNIQUEIDENTIFIER,
[DifferentialBaseLSN]	NUMERIC(25,0),
[DifferentialBaseGUID]	UNIQUEIDENTIFIER,
[IsReadOnly]			INT,
[IsPresent]				INT,
[TDEThumbprint]			VARBINARY(32))

INSERT INTO @FileGroups
SELECT		N'
FILEGROUP = N''' + name + N''', '
			,0

FROM		sys.filegroups fg

WHILE EXISTS(SELECT 1 FROM @FileGroups WHERE Processed = 0)
BEGIN
	SELECT TOP 1 @BackupSegment = BackupSegment FROM @FileGroups WHERE Processed = 0

	SET @SQL = @SQL + @BackupSegment

	UPDATE @FileGroups
	SET Processed = 1
	WHERE BackupSegment = @BackupSegment
END

SET @SQL = SUBSTRING(@SQL, 0, LEN(@SQL)) + '

TO'

WHILE EXISTS(SELECT 1 FROM @BackupFiles WHERE Processed = 0)
BEGIN
	SELECT TOP 1 @BackupSegment = FileNameAndPath FROM @BackupFiles WHERE Processed = 0

	SET @SQL = @SQL + '
DISK = N''' + @BackupSegment + ''','

	UPDATE @BackupFiles
	SET Processed = 1
	WHERE FileNameAndPath = @BackupSegment
END

SET @SQL = SUBSTRING(@SQL, 0, LEN(@SQL)) + '

WITH NOFORMAT, NOINIT, NAME = N''' + @Database + ' FULL Backup'', 
SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10
GO
'

SELECT @SQL AS [Backup Script]

-- Recovery script

UPDATE @FileGroups SET Processed = 0
UPDATE @BackupFiles SET Processed = 0

SET @SQL = 'RESTORE FILELISTONLY

FROM'

WHILE EXISTS(SELECT 1 FROM @BackupFiles WHERE Processed = 0)
BEGIN
	SELECT TOP 1 @BackupSegment = FileNameAndPath FROM @BackupFiles WHERE Processed = 0

	SET @SQL = @SQL + '
DISK = N''' + @BackupSegment + ''','

	UPDATE @BackupFiles
	SET Processed = 1
	WHERE FileNameAndPath = @BackupSegment
END

SET @SQL = SUBSTRING(@SQL, 0, LEN(@SQL))

INSERT INTO @Files 
EXEC(@SQL)

SET @SQL = 'RESTORE DATABASE [' + @Database + ']' + SUBSTRING(@SQL, 21, LEN(@SQL))

SET @SQL = @SQL + '

WITH
'

WHILE EXISTS(SELECT 1 FROM @Files)
BEGIN
	SELECT TOP 1 @BackupSegment = 'MOVE N''' + LogicalName + ''' TO N''' + PhysicalName + ''',
' FROM @Files

	SET @SQL = @SQL + @BackupSegment

	DELETE FROM @Files
	WHERE 'MOVE N''' + LogicalName + ''' TO N''' + PhysicalName + ''',
' = @BackupSegment
END

SET @SQL = @SQL + '
NORECOVERY, NOUNLOAD, STATS = 10'

--TODO: Think of a good way to replace the paths so they match the detination server.
SELECT @SQL = REPLACE(@SQL, 'D:\SQLServer\Data', 'E:\Data\Data')
SELECT @SQL = REPLACE(@SQL, 'E:\SQLServer\Data', 'E:\Data\Data')
SELECT @SQL = REPLACE(@SQL, 'F:\SQLServer\Data', 'E:\Data\Data')

SELECT @SQL AS [Restore Script]

/*
RESTORE LOG OLL_Morrisons  FROM
DISK = 'N:\LogShipping\logs\LS_oll_morrisons_migrated_TLog_20150430140251.LogBak' --70504.LogBak'
WITH FILE = 1,
NORECOVERY, 

MOVE 'OLL_LiveReadyDB_dat' TO 'L:\Data\OLL_Morrisons_1.mdf', 
MOVE 'OLL_Morrisons_1_Data' TO 'L:\Data\OLL_Morrisons_2.ndf', 
MOVE 'CONFIG_DATA' TO 'L:\Data\OLL_Morrisons_3.ndf', 
MOVE 'CONFIG_CUSTOMER_DATA' TO 'L:\Data\OLL_Morrisons_4.ndf', 
MOVE 'CONFIG_HIGH_UPDATE_DATA' TO 'L:\Data\OLL_Morrisons_5.ndf', 
MOVE 'LOG_CHECKING_DATA' TO 'L:\Data\OLL_Morrisons_6.ndf', 
MOVE 'LOG_CORE_DATA' TO 'L:\Data\OLL_Morrisons_7.ndf', 
MOVE 'LOG_REFERENCED_DATA' TO 'L:\Data\OLL_Morrisons_8.ndf', 
MOVE 'MAINTENANCE_DATA' TO 'L:\Data\OLL_Morrisons_9.ndf', 
MOVE 'SPECIFIC_DATA' TO 'L:\Data\OLL_Morrisons_10.ndf', 
MOVE 'TOTALS_DATA_2' TO 'L:\Data\OLL_Morrisons_11.NDF', 
MOVE 'WEB_DATA' TO 'L:\Data\OLL_Morrisons_12.ndf', 
MOVE 'OLL_MORRISONS_12_Data' TO 'L:\Data\OLL_Morrisons_13.ndf', 
MOVE 'OLL_LiveReadyDB_log' TO 'M:\Logs\OLL_Morrisons_14.LDF', NOUNLOAD, STATS = 10
*/

/*
RESTORE DATABASE [EM_OLL_OLTP_UAT]  

FROM 
DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_1.bak', 
DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_2.bak',
DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_3.bak',
DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_4.bak',

DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_5.bak',
DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_6.bak',
DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_7.bak',
DISK = N'D:\AG init backups\EM_OLL_OLTP_UAT FULL Backup AG Init_8.bak'

WITH  
MOVE 'EM_OLL_OLTP_PrimaryData' TO 'E:\SQLServer\Data\EM_OLL_OLTP_PrimaryData.mdf', 
MOVE 'EM_OLL_OLTP_TransLog' TO 'E:\SQLServer\Data\EM_OLL_OLTP_TransLog.ldf', 
MOVE 'EM_OLL_OLTP_UserData01' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_UserData01.ndf', 
MOVE 'EM_OLL_OLTP_ETLStagingData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_ETLStagingData01.ndf', 
MOVE 'EM_OLL_OLTP_ConfigData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_ConfigData01.ndf', 
MOVE 'EM_OLL_OLTP_ReferenceData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_ReferenceData01.ndf', 
MOVE 'EM_OLL_OLTP_LogData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_LogData01.ndf', 
MOVE 'EM_OLL_OLTP_SettlementData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_SettlementData01.ndf', 
MOVE 'EM_OLL_OLTP_WebData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_WebData01.ndf', 
MOVE 'EM_OLL_OLTP_TransientData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_TransientData01.ndf', 
MOVE 'EM_OLL_OLTP_MaintData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_MaintData01.ndf', 
MOVE 'EM_OLL_OLTP_CDCData01' TO 'E:\SQLServer\Data\EM_OLL_OLTP_CDCData01.ndf', 
MOVE 'FIO_TEST' TO 'F:\SQLServer\Data\EM_OLL_OLTP_FIOTEST.ndf', 
MOVE 'UltraFastRW_NP_CL_LOG' TO 'D:\SQLServer\DATA\EM_OLL_OLTP_UltraFastRW_NP_CL_LOG.ndf', 
MOVE 'UltraFastRW_NP_NC_LOG' TO 'D:\SQLServer\DATA\EM_OLL_OLTP_UltraFastRW_NP_NC_LOG.ndf', 
MOVE 'VeryFastRW_NP_CL_LOG' TO 'E:\SQLServer\Data\EM_OLL_OLTP_VeryFastRW_NP_CL_LOG.ndf', 
MOVE 'VeryFastRW_NP_NC_LOG' TO 'E:\SQLServer\Data\EM_OLL_OLTP_VeryFastRW_NP_NC_LOG.ndf', 
MOVE 'FastReadSlowWrite_NP_CL_LOG' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_FastReadSlowWrite_NP_CL_LOG.ndf', 
MOVE 'FastReadSlowWrite_NP_NC_LOG' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_FastReadSlowWrite_NP_NC_LOG.ndf', 
MOVE 'UltraFastRW_NP_CL_CFG' TO 'D:\SQLServer\DATA\EM_OLL_OLTP_UltraFastRW_NP_CL_CFG.ndf', 
MOVE 'UltraFastRW_NP_NC_CFG' TO 'D:\SQLServer\DATA\EM_OLL_OLTP_UltraFastRW_NP_NC_CFG.ndf', 
MOVE 'VeryFastRW_NP_CL_CFG' TO 'E:\SQLServer\Data\EM_OLL_OLTP_VeryFastRW_NP_CL_CFG.ndf', 
MOVE 'VeryFastRW_NP_NC_CFG' TO 'E:\SQLServer\Data\EM_OLL_OLTP_VeryFastRW_NP_NC_CFG.ndf', 
MOVE 'FastReadSlowWrite_NP_CL_CFG' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_FastReadSlowWrite_NP_CL_CFG.ndf', 
MOVE 'FastReadSlowWrite_NP_NC_CFG' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_FastReadSlowWrite_NP_NC_CFG.ndf', 
MOVE 'UltraFastRW_NP_CL_UTL' TO 'D:\SQLServer\DATA\EM_OLL_OLTP_UltraFastRW_NP_CL_UTL.ndf', 
MOVE 'UltraFastRW_NP_NC_UTL' TO 'D:\SQLServer\DATA\EM_OLL_OLTP_UltraFastRW_NP_NC_UTL.ndf', 
MOVE 'VeryFastRW_NP_CL_UTL' TO 'E:\SQLServer\Data\EM_OLL_OLTP_VeryFastRW_NP_CL_UTL.ndf', 
MOVE 'VeryFastRW_NP_NC_UTL' TO 'E:\SQLServer\Data\EM_OLL_OLTP_VeryFastRW_NP_NC_UTL.ndf', 
MOVE 'FastReadSlowWrite_NP_CL_UTL' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_FastReadSlowWrite_NP_CL_UTL.ndf', 
MOVE 'FastReadSlowWrite_NP_NC_UTL' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_FastReadSlowWrite_NP_NC_UTL.ndf', 
MOVE 'READ_ONLY' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_READ_ONLY.ndf', 
MOVE 'ULTRAFAST_EMERGENCY' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_ULTRAFAST_EMERGENCY.ndf', 
MOVE 'VeryFAST_EMERGENCY' TO 'E:\SQLServer\Data\EM_OLL_OLTP_VeryFAST_EMERGENCY.ndf', 
MOVE 'FAST_EMERGENCY' TO 'D:\SQLServer\DATA\EM_OLL_OLTP_FAST_EMERGENCY.ndf', 
MOVE 'DEFAULT_FG' TO 'F:\SQLServer\DATA\EM_OLL_OLTP_DEFAULT_FG.ndf', 
MOVE 'xyz_log' TO 'F:\SQLServer\Log\xyz_01.ldf', 
MOVE 'EM_OLL_OLTP_RowTotaller' TO 'F:\SQLServer\DATA\_RowTotaller.ndf',

NORECOVERY, NOUNLOAD, STATS = 10
*/

/*
BACKUP DATABASE [EM_OLL_OLTP_UAT] 

FILEGROUP = N'PRIMARY',
FILEGROUP = N'UserData',
FILEGROUP = N'ETLStaging',
FILEGROUP = N'Config',
FILEGROUP = N'Reference',
FILEGROUP = N'Log',
FILEGROUP = N'Settlement',
FILEGROUP = N'Web',
FILEGROUP = N'Transient',
FILEGROUP = N'CDC',
FILEGROUP = N'Maint',
FILEGROUP = N'FIO_TEST',
FILEGROUP = N'UltraFastRW_NP_CL_LOG',
FILEGROUP = N'UltraFastRW_NP_NC_LOG',
FILEGROUP = N'VeryFastRW_NP_CL_LOG',
FILEGROUP = N'VeryFastRW_NP_NC_LOG',
FILEGROUP = N'FastReadSlowWrite_NP_CL_LOG',
FILEGROUP = N'FastReadSlowWrite_NP_NC_LOG',
FILEGROUP = N'UltraFastRW_NP_CL_CFG',
FILEGROUP = N'UltraFastRW_NP_NC_CFG',
FILEGROUP = N'VeryFastRW_NP_CL_CFG',
FILEGROUP = N'VeryFastRW_NP_NC_CFG',
FILEGROUP = N'FastReadSlowWrite_NP_CL_CFG',
FILEGROUP = N'FastReadSlowWrite_NP_NC_CFG',
FILEGROUP = N'UltraFastRW_NP_CL_UTL',
FILEGROUP = N'UltraFastRW_NP_NC_UTL',
FILEGROUP = N'VeryFastRW_NP_CL_UTL',
FILEGROUP = N'VeryFastRW_NP_NC_UTL',
FILEGROUP = N'FastReadSlowWrite_NP_CL_UTL',
FILEGROUP = N'FastReadSlowWrite_NP_NC_UTL',
FILEGROUP = N'READ_ONLY',
FILEGROUP = N'ULTRAFAST_EMERGENCY',
FILEGROUP = N'VeryFAST_EMERGENCY',
FILEGROUP = N'FAST_EMERGENCY',
FILEGROUP = N'DEFAULT_FG',
FILEGROUP = N'RowTotallerData'

TO  
DISK = N'D:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_1.bak', 
DISK = N'D:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_2.bak',
DISK = N'D:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_3.bak',
DISK = N'D:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_4.bak',

DISK = N'E:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_5.bak',
DISK = N'E:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_6.bak',
DISK = N'E:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_7.bak',
DISK = N'E:\SQLServer\EM_OLL_OLTP_UAT FULL Backup AG Init_8.bak'

WITH NOFORMAT, NOINIT,  NAME = N'EM_OLL_OLTP_UAT FULL Backup', 
SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO 
*/


 
 