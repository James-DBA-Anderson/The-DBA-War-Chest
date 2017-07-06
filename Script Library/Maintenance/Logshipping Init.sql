
------------------------------------------------------------------------------------- 
-- 2013-12-12
-- James Anderson
-----------------------------------------
-- Wait for first log restore before secondary db becomes readable. 

-- To fix logshipping that has been broken:
--	1. Remove logshipping from primary database properties window
--	2. Remove all files in the LogShipping folder on the primary server for the desired database
--	3. Run this script on primary and then secondary server.
-----------------------------------------
-- DECLARE Variables
------------------------------------------------------------------------------------- 
USE [MSDB]

DECLARE @Database NVARCHAR(max), @Databases NVARCHAR(max), @BackupDir NVARCHAR(max), @BackupDirectory NVARCHAR(max), @BackupShare NVARCHAR(max), @BackupJobName NVARCHAR(max),
@ScheduleName NVARCHAR(max), @SecondaryServer NVARCHAR(max), @SecondaryDatabase NVARCHAR(max), @PrimaryServer NVARCHAR(max), @PrimaryDatabase NVARCHAR(max),
@BackupSourceDirectory NVARCHAR(max), @BackupDestinationDirectory NVARCHAR(max), @CopyJobName NVARCHAR(max), @RestoreJobName NVARCHAR(max), @CopyScheduleName NVARCHAR(max),
@RestoreScheduleName NVARCHAR(max), @SecondaryServerDataDirectoy NVARCHAR(max), @SecondaryServerLogDirectoy NVARCHAR(max), @SQL NVARCHAR(max), @Date INT, 
@LogBackupScheduleMinuteOffSET CHAR(6), @CopyScheduleMinuteOffSET CHAR(6), @RestoreScheduleMinuteOffSET CHAR(6)

-- Randomise the start minute for each schedule so IO is spread out. Start ranges FROM 120000 to 120900
SELECT	@LogBackupScheduleMinuteOffSET = CONVERT(INT, '060' + CONVERT(CHAR(1), ROUND(RAND() * 9, 0)) + '00'), 
		@CopyScheduleMinuteOffSET = CONVERT(INT, '000' + CONVERT(CHAR(1), ROUND(RAND() * 9, 0)) + '00'), 
		@RestoreScheduleMinuteOffSET = CONVERT(INT, '190' + CONVERT(CHAR(1), ROUND(RAND() * 9, 0)) + '00')

DECLARE @DBs TABLE
(DBName NVARCHAR(100))

------------------------------------------------------------------------------------- 
-- SET Variables
-- Create a network share accessible by both servers and the SQL service account running the instances (@BackupDirectory)
-- Create a local folder on the secondary server accessible to the secondary SQL service account (@BackupDestinationDirectory)
-- Runs this query FROM the SQL instance you DECLARE as @PrimaryServer
-- THEN change connection to the secondary server and run the query again on the secondary server
------------------------------------------------------------------------------------- 

-- Use code below to generate a comma seperated list of DBs for the @Databases param. Uncomment and SET @aa as the value of @Databases
DECLARE @aa VARCHAR (max)
SET @aa = ''

SELECT @aa = coalesce (CASE WHEN @aa = '' THEN name ELSE @aa + ',' + name END,'')

FROM sys.databases 
WHERE database_id > 4 and name not like '%$%' -- Check status of DB - restoring, offline
ORDER BY name
SELECT @aa

-- ,AA,ACCA,Admin,AECOM,Amgen,AnglianCountryInns,ASOS,Atradius,autotrader,BankOfEngland,BankOfEnglandReporting,BAT,BenefexDemo,BenefexDemoPreview,BenefexRewardHub,BoAIE,BoAUK,BoAUKReporting,Boots,BreezeAndWyles,BT,BTUSA,CAA,CCEUS,CeladorRadio,Centrica,CentricaReporting,CHDA,Communications,Communisis,Countryside,CountrysideReporting,CroweCW,CroweCWReporting,CSC,DeBeers,Deliveroo,Demo_AEBoE20160617,Demo_AELSH20160617,Demo_AELSL20160617,Dentons,Doosan,Dune,EDF_Energy,EIML,Elmah,EMISGroup,Eon,ERS,Experian,ExperianReporting,Freightliner,Hastings,HML,holidayextras,Hs2,HS2122,HTC,IMSHealth,Ingredion,interserve,IOP,ITTest,ITV,jameshay,Jigsaw,Kambi,Kenwood,KonicaMinolta,KrestonReeves,LendLease,LSE,LSH,LSL,Maintenance,Markel,MarksAndSpencer,Marshall,Marvellous,MBDA,MBNA,MDLZ,MDLZROI,Micheldever,MoneySupermarket,MSD,MWSolicitors,Nexen,NGN,NortonRoseFulbright,Ombudsman,Openwork,OrdnanceSurvey,Philips,PhilipsLighting,PlusNet,QVC,RationalGroup,Reeves,Reports,Safestyle,sainsburys,Selfridges,softwarebox,SSB,SSBCI,SSBCIReporting,SSBReporting,SSP,TeachFirst,TetraPakRoI,TetraPakUK,TheCarFinanceCompany,ThomsonReuters,TotalEP,TotalGP,TotalLOR,TotalUK,TravelWeeklyGroup,TRW,Tyco,Uniper,Unisys,Unisys122,WalesAndWest,wates,Wolseley,Worldpay,WorleyParsons,ZendeskMultibrand


--------------------------------------------------------------------------------------- 
-- Section 1
--------------------------------------------------------------------------------------- 

SET @SQL = 'SELECT ''' + REPLACE(@Databases, ',', ''' UNION SELECT ''') + ''''

INSERT INTO @DBs
EXEC SP_ExecuteSql @SQLToExecute = @SQL

IF @@ServerName = @PrimaryServer
BEGIN
	WHILE Exists(SELECT * FROM @DBs)
	BEGIN
		SET @Database = (SELECT TOP 1 DBName FROM @DBs)

		SELECT	@BackupDirectory			= @BackupDir + '\' + @Database,
				@BackupJobName				= 'LSBackup_'+@Database,				
				@SecondaryDatabase			= @Database,		
				@PrimaryDatabase			= @Database,
				@ScheduleName				= 'LSBackupSchedule_' + @PrimaryServer,
				@BackupShare				= @BackupDirectory,
				@BackupSourceDirectory		= @BackupDirectory		

		IF ((SELECT recovery_model FROM sys.databases WHERE name = @Database) > 1) -- 1 = Full
		BEGIN
			PrINT 'SETting ' + @Database + ' to Full recovery mode'
			SET @SQL = N'ALTER DATABASE [' + @Database + '] SET RECOVERY FULL;' 
			EXEC SP_ExecuteSql @SQLToExecute = @SQL	
		END

		DECLARE @LS_BackupJobId	AS UNIQUEIDENTIFIER 
		DECLARE @LS_PrimaryId	AS UNIQUEIDENTIFIER 
		DECLARE @SP_Add_RetCode	As INT 
		
		SELECT @LS_BackupJobId = NULL, @LS_PrimaryId = NULL, @SP_Add_RetCode = NULL

		SET @SQL = 'BACKUP DATABASE [' + @Database + '] TO  DISK = ''' + @BackupDirectory + '\' + @Database + '.bak'' 
					WITH NOFORMAT, NOINIT,  NAME = '' ' + @Database + '-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10'
		EXEC SP_ExecuteSql @SQLToExecute = @SQL	

		EXEC @SP_Add_RetCode = master.dbo.sp_add_log_shipping_primary_database 
				@database = @Database
				,@backup_directory = @BackupDirectory 
				,@backup_share = @BackupShare
				,@backup_job_name = @BackupJobName 
				,@backup_retention_period = 2880
				,@backup_threshold = 840 
				,@threshold_alert_enabled = 1
				,@history_retention_period = 5760 
				,@backup_job_id = @LS_BackupJobId OUTPUT 
				,@primary_id = @LS_PrimaryId OUTPUT 
				,@overwrite = 1 

		IF (@@ERROR = 0 AND @SP_Add_RetCode = 0) 
		BEGIN 

		DECLARE @LS_BackUpScheduleUID	As UNIQUEIDENTIFIER 
		DECLARE @LS_BackUpScheduleID	AS INT 
		SELECT @Date = CONVERT(CHAR(10), GETDATE(), 112), @LS_BackUpScheduleUID = null

		EXEC msdb.dbo.sp_add_schedule 
				@schedule_name = @ScheduleName
				,@enabled = 1 
				,@freq_type = 4 
				,@freq_INTerval = 1 
				,@freq_subday_type = 4 
				,@freq_subday_INTerval = 30 
				,@freq_recurrence_factor = 0 
				,@active_start_date = @Date 
				,@active_END_date = 99991231 
				,@active_start_time = @LogBackupScheduleMinuteOffSET 
				,@active_END_time = 203900 
				,@schedule_uid = @LS_BackUpScheduleUID OUTPUT 
				,@schedule_id = @LS_BackUpScheduleID OUTPUT; 
				
		EXEC msdb.dbo.sp_attach_schedule @job_id = @LS_BackupJobId ,@schedule_id = @LS_BackUpScheduleID  

		EXEC msdb.dbo.sp_update_job @job_id = @LS_BackupJobId ,@enabled = 1 
		END 

		EXEC master.dbo.sp_add_log_shipping_alert_job 

		EXEC master.dbo.sp_add_log_shipping_primary_secondary 
				@primary_database = @Database 
				,@secondary_server = @SecondaryServer
				,@secondary_database = @SecondaryDatabase
				,@overwrite = 1 
				
		DELETE FROM @DBs WHERE DBName = @Database
	END
END
-- ****** END: Script to be run at Primary ******

------------------------------------------------------------------------------------- 
-- Section 2
------------------------------------------------------------------------------------- 

-- ****** BEGIN: Script to be run at Secondary ******
IF (@@ServerName = @SecondaryServer)
BEGIN
	WHILE Exists(SELECT * FROM @DBs)
	BEGIN
		SET @Database = (SELECT TOP 1 DBName FROM @DBs)

		SELECT	@BackupDestinationDirectory	= 'L:\LogShipping\' + @Database

		SELECT 	@BackupJobName				= 'LSBackup_'+@Database,				
				@SecondaryDatabase			= @Database,		
				@PrimaryDatabase			= @Database,		
				@CopyJobName				= 'LSCopy_' + @SecondaryServer + '_' + @Database,
				@RestoreJobName				= 'LSRestore_' + @SecondaryServer + '_' + @Database,
				@ScheduleName				= 'LSBackupSchedule_' + @PrimaryServer + @Database,
				@BackupShare				= @BackupDir,
				@BackupSourceDirectory		= @BackupDir + '\' + @Database,
				@CopyScheduleName			= @Database + 'DefaultCopyJobSchedule',
				@RestoreScheduleName		= @Database + 'DefaultRestoreJobSchedule'
		
		DECLARE @SQLSecondary NVARCHAR(max)

		DECLARE @Restore table
		(LogicalName NVARCHAR(128)
		,PhysicalName NVARCHAR(260)
		,[Type] CHAR(1)
		,FileGroupName NVARCHAR(128)
		,Size NUMERIC(20,0)
		,MaxSize NUMERIC(20,0)
		,FileId BIGINT
		,CreateLSN NUMERIC(25,0)
		,DropLSN NUMERIC(25,0)
		,UniqueID UNIQUEIDENTIFIER
		,ReadOnlyLSN NUMERIC(25,0)
		,ReadWriteLSN NUMERIC(25,0)
		,BackupSizeInBytes BIGINT
		,SourceBlockSize INT
		,FileGroupId INT
		,LogGroupGUID UNIQUEIDENTIFIER
		,DIFferentialBaseLSN NUMERIC(25,0)
		,DIFferentialBaseGUID UNIQUEIDENTIFIER
		,IsReadOnly BIT
		,IsPresent BIT
		,TDEThumbprINT VARBINARY(32)
		,SnapshotUrl NVARCHAR(MAX)
		)

		--Read file list
		SET @SQLSecondary = 'RESTORE FILELISTONLY FROM DISK = ''' + @BackupSourceDirectory + '\' + @Database + '.bak''  With File = 1'
		
		INSERT INTO @Restore
		EXEC SP_ExecuteSql @SQLToExecute = @SQLSecondary

		DECLARE @LogFileLogicalName NVARCHAR(50)
		DECLARE @DataFileLogicalName NVARCHAR(50)

		SELECT @DataFileLogicalName = LogicalName FROM @Restore WHERE FileId = 1
		SELECT @LogFileLogicalName = LogicalName FROM @Restore WHERE FileId = 2

		SET @SQLSecondary = '

		RESTORE DATABASE ' + @Database + '
		FROM	DISK = ''' + @BackupSourceDirectory + '\' + @Database + '.bak'' 
		WITH	NORECOVERY, 
				MOVE ''' + @DataFileLogicalName + ''' To ''' + @SecondaryServerDataDirectoy + '\' + @Database + '.mdf'',
				MOVE ''' + @LogFileLogicalName + ''' To ''' + @SecondaryServerLogDirectoy + '\' + @Database + '.ldf'', REPLACE '
			
		EXEC SP_ExecuteSql @SQLToExecute = @SQLSecondary	

		DECLARE @LS_Secondary__CopyJobId	AS UNIQUEIDENTIFIER 
		DECLARE @LS_Secondary__RestoreJobId	AS UNIQUEIDENTIFIER 
		DECLARE @LS_Secondary__SecondaryId	AS UNIQUEIDENTIFIER 
		DECLARE @LS_Add_RetCode	AS INT 
		
		SELECT @LS_Secondary__CopyJobId = NULL, @LS_Secondary__RestoreJobId = NULL, @LS_Secondary__SecondaryId = NULL, @LS_Add_RetCode = NULL

		EXEC @LS_Add_RetCode = master.dbo.sp_add_log_shipping_secondary_primary 
				@primary_server = @PrimaryServer
				,@primary_database = @PrimaryDatabase
				,@backup_source_directory = @BackupSourceDirectory
				,@backup_destination_directory = @BackupDestinationDirectory
				,@copy_job_name = @CopyJobName 
				,@restore_job_name = @RestoreJobName
				,@file_retention_period = 2880 
				,@overwrite = 1 
				,@copy_job_id = @LS_Secondary__CopyJobId OUTPUT 
				,@restore_job_id = @LS_Secondary__RestoreJobId OUTPUT 
				,@secondary_id = @LS_Secondary__SecondaryId OUTPUT 

		IF (@@ERROR = 0 AND @LS_Add_RetCode = 0) 
		BEGIN 

		DECLARE @LS_SecondaryCopyJobScheduleUID	AS UNIQUEIDENTIFIER 
		DECLARE @LS_SecondaryCopyJobScheduleID	AS INT 
		
		SELECT @LS_SecondaryCopyJobScheduleUID = NULL, @LS_SecondaryCopyJobScheduleID = NULL

		EXEC msdb.dbo.sp_add_schedule 
				@schedule_name = @CopyScheduleName
				,@enabled = 1 
				,@freq_type = 4 
				,@freq_INTerval = 1 
				,@freq_subday_type = 4 
				,@freq_subday_INTerval = 30
				,@freq_recurrence_factor = 0 
				,@active_start_date = 20131212 
				,@active_END_date = 99991231 
				,@active_start_time = @CopyScheduleMinuteOffSET 
				,@active_END_time = 235900 
				,@schedule_uid = @LS_SecondaryCopyJobScheduleUID OUTPUT 
				,@schedule_id = @LS_SecondaryCopyJobScheduleID OUTPUT 

		EXEC msdb.dbo.sp_attach_schedule 
				@job_id = @LS_Secondary__CopyJobId 
				,@schedule_id = @LS_SecondaryCopyJobScheduleID  

		DECLARE @LS_SecondaryRestoreJobScheduleUID	AS UNIQUEIDENTIFIER 
		DECLARE @LS_SecondaryRestoreJobScheduleID	AS INT 
		
		SELECT @LS_SecondaryRestoreJobScheduleUID = NULL, @LS_SecondaryRestoreJobScheduleID = NULL

		EXEC msdb.dbo.sp_add_schedule 
				@schedule_name = @RestoreScheduleName
				,@enabled = 1 
				,@freq_type = 4 
				,@freq_INTerval = 1 
				,@freq_subday_type = 4 
				,@freq_subday_INTerval = 30 
				,@freq_recurrence_factor = 0 
				,@active_start_date = 20131212 
				,@active_END_date = 99991231 
				,@active_start_time = @RestoreScheduleMinuteOffSET 
				,@active_END_time = 220000 
				,@schedule_uid = @LS_SecondaryRestoreJobScheduleUID OUTPUT 
				,@schedule_id = @LS_SecondaryRestoreJobScheduleID OUTPUT 

		EXEC msdb.dbo.sp_attach_schedule 
				@job_id = @LS_Secondary__RestoreJobId 
				,@schedule_id = @LS_SecondaryRestoreJobScheduleID  
		END 

		DECLARE @LS_Add_RetCode2	AS INT 
		SET @LS_Add_RetCode2 = NULL

		IF (@@ERROR = 0 AND @LS_Add_RetCode = 0) 
		BEGIN 

		EXEC @LS_Add_RetCode2 = master.dbo.sp_add_log_shipping_secondary_database 
				@secondary_database = @SecondaryDatabase 
				,@primary_server = @PrimaryServer
				,@primary_database = @PrimaryDatabase
				,@restore_delay = 0 
				,@restore_mode = 0
				,@disconnect_users	= 1
				,@restore_threshold = 1680 
				,@threshold_alert_enabled = 1 
				,@history_retention_period	= 5760 
				,@overwrite = 1 
		END 

		IF (@@error = 0 AND @LS_Add_RetCode = 0) 
		BEGIN 

		EXEC msdb.dbo.sp_update_job @job_id = @LS_Secondary__CopyJobId ,@enabled = 1 

		EXEC msdb.dbo.sp_update_job @job_id = @LS_Secondary__RestoreJobId ,@enabled = 1 

		END 
		DELETE FROM @DBs WHERE DBName = @Database
	END
END 
ELSE IF (@@SERVERNAME <> @PrimaryServer)
BEGIN
	SELECT 'You are not connected to the primmary server ('+ ISNULL(@PrimaryServer, '')+') or the secondary server ('+ ISNULL(@SecondaryDatabase, '') +')' AS Err
END
-- ****** END: Script to be run at Secondary ******


