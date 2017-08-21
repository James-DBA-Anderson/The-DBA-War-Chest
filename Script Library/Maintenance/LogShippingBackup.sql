USE [msdb]
GO

/****** Object:  Job [LogShippingBackup]    Script Date: 21/08/2017 09:40:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Log Shipping]    Script Date: 21/08/2017 09:40:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Log Shipping' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Log Shipping'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'LogShippingBackup', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Log Shipping', 
		@owner_login_name=N'BFX\jamesanderson', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [BackupDBs]    Script Date: 21/08/2017 09:40:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'BackupDBs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
-- Set the root backup directory ----------------------

DECLARE @BackupDir NVARCHAR(MAX) = N''\\BFX-HV-BAK\TestSQLLS'',
		@Debug BIT = 0;

-------------------------------------------------------

DECLARE @DBs TABLE (DBName SYSNAME, RecoveryModel SYSNAME, Processed BIT DEFAULT 0)

DECLARE @DBName SYSNAME, 
		@RecoveryModel SYSNAME, 
		@SQL NVARCHAR(MAX), 
		@Error BIT = 0,
		@Instance NVARCHAR(100) = SUBSTRING(CONVERT(NVARCHAR(100), SERVERPROPERTY(''SERVERNAME'')), CHARINDEX(''\'', CONVERT(NVARCHAR(100), SERVERPROPERTY(''SERVERNAME''))) + 1, 100),
		@DatabaseFolder NVARCHAR(256),
		@BackupPathBase NVARCHAR(MAX),
		@BackupPath NVARCHAR(MAX),
		@ErrMsg NVARCHAR(MAX),
		@FullErrMsg NVARCHAR(MAX),
		@CurrentLogLSN numeric(25,0)

INSERT @DBs(DBName, RecoveryModel)
SELECT d.name, d.recovery_model_desc
FROM sys.databases d
WHERE d.name NOT IN (''master'',''tempdb'',''msdb'',''model'',''ReportServer'',''ReportServerTempDB'',''ReportServerVnext'',''ReportServerVnextTempDB'')
AND d.state = 0 -- online
ORDER BY d.name

WHILE EXISTS(SELECT * FROM @DBs d WHERE d.Processed = 0)
BEGIN
	SELECT TOP 1 @DBName = DBName, @RecoveryModel = RecoveryModel FROM @DBs WHERE Processed = 0;

	SET @Error = 0;

	PRINT ''
====================
Processing '' + ISNULL(@DBName, ''unknown database'');

	-- Dynamically create a folder for each database.
    BEGIN TRY
		IF @Error = 0
		BEGIN
			SET @DatabaseFolder = @BackupDir + N''\'' + @Instance + N''\'' + @DBName;
			
			PRINT ''Creating folder: '' + @DatabaseFolder;
			IF @Debug = 0
				EXEC master.sys.xp_create_subdir @DatabaseFolder;
		END
	END TRY
	BEGIN CATCH
		SET @Error = 1;
		SET @ErrMsg = ERROR_MESSAGE();
		SET @FullErrMsg = ''Failed to create folder for '' + ISNULL(@DBName, ''unknown database'') + '': '' + @ErrMsg;
		RAISERROR(@FullErrMsg, 16, 1);
	END CATCH

	SET @BackupPathBase = N'''''''' + @DatabaseFolder + N''\'' + @DBName + N''_'' + CONVERT(NVARCHAR(20), GETDATE(), 112) + ''-'' + REPLACE(SUBSTRING(CONVERT(NVARCHAR(20), GETDATE(), 114), 0, 9), '':'', '''')

	IF @RecoveryModel <> N''FULL''
	BEGIN
		SET @SQL = N''
--------------------
USE [master]
ALTER DATABASE '' + QUOTENAME(@DBName) + N'' SET RECOVERY FULL WITH NO_WAIT;
--------------------'';

		BEGIN TRY
			IF @Error = 0
			BEGIN
				PRINT @SQL
				IF @Debug = 0
					EXEC sp_ExecuteSQL @SQL
			END
		END TRY
		BEGIN CATCH
			SET @Error = 1;
			SET @ErrMsg = ERROR_MESSAGE();
			SET @FullErrMsg = ''Failed to set FULL recovery for LogShipping on '' + ISNULL(@DBName, ''unknown database'') + '': '' + @ErrMsg;
			RAISERROR(@FullErrMsg, 16, 1);
		END CATCH
	END

	SELECT @CurrentLogLSN = last_log_backup_lsn
    FROM sys.databases d
	JOIN sys.database_recovery_status rs ON d.database_id = rs.database_id
    WHERE d.name = @DBName

	IF @CurrentLogLSN IS NULL
	BEGIN
		SET @BackupPath = @BackupPathBase + N''.bak'' + N'''''''';

		SET @SQL = N''
--------------------
USE [master]
BACKUP DATABASE '' + QUOTENAME(@DBName) + ''
TO DISK = '' + @BackupPath + N''
WITH COMPRESSION, STATS = 100;
--------------------'';

		BEGIN TRY
			IF @Error = 0
			BEGIN
				PRINT @SQL
				IF @Debug = 0
					EXEC sp_ExecuteSQL @SQL
			END
		END TRY
		BEGIN CATCH
			SET @Error = 1;
			SET @ErrMsg = ERROR_MESSAGE();
			SET @FullErrMsg = ''Failed to initiate LogShipping witha full backup for '' + ISNULL(@DBName, ''unknown database'') + '': '' + @ErrMsg;
			RAISERROR(@FullErrMsg, 16, 1);
		END CATCH		
	END
	
	SET @BackupPath = @BackupPathBase + N''.trn'' + N'''''''';

	SET @SQL = N''
--------------------
USE [master]
BACKUP LOG '' + QUOTENAME(@DBName) + ''
TO DISK = '' + @BackupPath + N''
WITH COMPRESSION, STATS = 100;
--------------------'';

	BEGIN TRY
		IF @Error = 0
		BEGIN
			PRINT @SQL
			IF @Debug = 0
				EXEC sp_ExecuteSQL @SQL
		END
	END TRY
	BEGIN CATCH
		SET @Error = 1;
		SET @ErrMsg = ERROR_MESSAGE();
		SET @FullErrMsg = ''LogShipping Failed for '' + ISNULL(@DBName, ''unknown database'') + '': '' + @ErrMsg;
		RAISERROR(@FullErrMsg, 16, 1);
	END CATCH

	PRINT ''
===================='';

	UPDATE @DBs SET Processed = 1 WHERE DBName = @DBName;
END', 
		@database_name=N'master', 
		@output_file_name=N'\\BFX-HV-BAK\TestSQLLS\Output\QA_LogShippingBackup_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Hour', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20170814, 
		@active_end_date=99991231, 
		@active_start_time=5000, 
		@active_end_time=235959, 
		@schedule_uid=N'8cc3c3ab-25bd-4623-b19a-14946f3b4253'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


