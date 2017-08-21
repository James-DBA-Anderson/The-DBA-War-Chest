USE [msdb]
GO

/****** Object:  Job [LogShippingRestore]    Script Date: 21/08/2017 09:41:57 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Log Shipping]    Script Date: 21/08/2017 09:41:57 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Log Shipping' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Log Shipping'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'LogShippingRestore', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Restore and remove backup files for log shipping.', 
		@category_name=N'Log Shipping', 
		@owner_login_name=N'QA_sa_disabled', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore backups]    Script Date: 21/08/2017 09:41:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore backups', 
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
-- This script uses the undocumented SPs sys.xp_dirtree and xp_Delete_file
-- These SPs require the sysadmin role 

-- Set params -----------------------------------------

DECLARE @BackupDir NVARCHAR(512) = N''N:\TestSQLLogShipping\SQLQA'',
		@StandbyMode BIT = 0,			-- Instances must be the same version for standby mode
		@DataFilePath NVARCHAR(MAX),	-- Leave unassigned to use instance default 
		@LogFilePath NVARCHAR(MAX),		-- Leave unassigned to use instance default
		@Debug BIT = 0;

-- DBs to ignore if their folder exists in the backup folder

DECLARE @DBs TABLE (DBName SYSNAME);
INSERT @DBs (DBName)
SELECT d.name
FROM sys.databases d
WHERE d.name NOT IN (''master'',''tempdb'',''msdb'',''model'',''ReportServer'',''ReportServerTempDB'',''ReportServerVnext'',''ReportServerVnextTempDB'');

-------------------------------------------------------

IF @DataFilePath IS NULL
	SET @DataFilePath = CONVERT(NVARCHAR(MAX), SERVERPROPERTY(''instancedefaultdatapath''));

IF @LogFilePath IS NULL
    SET @LogFilePath = CONVERT(NVARCHAR(MAX), SERVERPROPERTY(''instancedefaultlogpath''));

-- Remove any trailing back slashes from params

IF @BackupDir LIKE N''%\''
	SET @BackupDir = SUBSTRING(@BackupDir, 0, LEN(@BackupDir))

IF @DataFilePath LIKE N''%\''
	SET @DataFilePath = SUBSTRING(@DataFilePath, 0, LEN(@DataFilePath))

IF @LogFilePath LIKE N''%\''
	SET @LogFilePath = SUBSTRING(@LogFilePath, 0, LEN(@LogFilePath))

DECLARE @Folders TABLE  
(
    id INT IDENTITY(1,1),
    subdirectory NVARCHAR(512),
    depth INT,
    isfile BIT,
	Processed BIT DEFAULT 0
);

DECLARE @Files TABLE  
(
    id INT IDENTITY(1,1),
    subdirectory NVARCHAR(512),
    depth INT,
    isfile BIT,
	Processed BIT DEFAULT 0
);

DECLARE @FileListTable TABLE 
(
    [LogicalName]           NVARCHAR(128),
    [PhysicalName]          NVARCHAR(260),
    [Type]                  CHAR(1),
    [FileGroupName]         NVARCHAR(128),
    [Size]                  NUMERIC(20,0),
    [MaxSize]               NUMERIC(20,0),
    [FileID]                BIGINT,
    [CreateLSN]             NUMERIC(25,0),
    [DropLSN]               NUMERIC(25,0),
    [UniqueID]              UNIQUEIDENTIFIER,
    [ReadOnlyLSN]           NUMERIC(25,0),
    [ReadWriteLSN]          NUMERIC(25,0),
    [BackupSizeInBytes]     BIGINT,
    [SourceBlockSize]       INT,
    [FileGroupID]           INT,
    [LogGroupGUID]          UNIQUEIDENTIFIER,
    [DifferentialBaseLSN]   NUMERIC(25,0),
    [DifferentialBaseGUID]  UNIQUEIDENTIFIER,
    [IsReadOnly]            BIT,
    [IsPresent]             BIT,
    [TDEThumbprint]         VARBINARY(32),
	[SnapshotUrl]			NVARCHAR(MAX)
);

DECLARE @DBName SYSNAME, 
		@RecoveryModel SYSNAME, 
		@SQL NVARCHAR(MAX), 
		@Error BIT = 0,
		@SubFolder NVARCHAR(512),
		@File NVARCHAR(512),
		@FileType NVARCHAR(4),
		@FileToDelete NVARCHAR(512),
		@LastFullBackupId INT,
		@ErrMsg NVARCHAR(MAX),
		@FullErrMsg NVARCHAR(MAX);

INSERT @Folders (subdirectory,depth,isfile)
EXEC master.sys.xp_dirtree @BackupDir, 1, 1;

delete from @Folders where subdirectory IN (''Admin'',''Aecom'',''JamesHay'',''Elmah'')

WHILE EXISTS(SELECT * FROM @Folders f WHERE f.Processed = 0)
BEGIN
	SELECT TOP 1 @DBName = subdirectory FROM @Folders WHERE Processed = 0;

	SET @Error = 0;

	PRINT ''
====================
Processing '' + ISNULL(@DBName, ''unknown database'');

	SET @SubFolder = @BackupDir + N''\'' + @DBName;	

	BEGIN TRY
		IF @Error = 0
		BEGIN
			PRINT @SubFolder;

			DELETE FROM @Files;

			INSERT @Files (subdirectory,depth,isfile)
			EXEC master.sys.xp_dirtree @SubFolder, 1, 1;			
		END
	END TRY
	BEGIN CATCH
		SET @Error = 1;
		SET @ErrMsg = ERROR_MESSAGE();
		SET @FullErrMsg = ''Failed to read backup files for '' + ISNULL(@DBName, ''unknown database'') + '': '' + @ErrMsg;
		RAISERROR(@FullErrMsg, 16, 1);
	END CATCH
	
	IF @Error = 0
	BEGIN
		-- Only look at files since the last full backup
		SELECT @LastFullBackupId = MAX(id)
		FROM @Files
		WHERE subdirectory LIKE ''%.bak''

		WHILE EXISTS(SELECT * FROM @Files f WHERE id < @LastFullBackupId)
		BEGIN
			SELECT TOP 1 @File = subdirectory FROM @Files WHERE id < @LastFullBackupId ORDER BY subdirectory;

			SET @FileToDelete = @SubFolder + N''\'' + @File;

			PRINT N''Deleting old file '' + @File;

			BEGIN TRY
				IF @Debug = 0				
					EXEC xp_Delete_file 0, @FileToDelete;
			END TRY
			BEGIN CATCH
				SET @Error = 1;
				SET @ErrMsg = ERROR_MESSAGE();
				SET @FullErrMsg = ''Failed to delete old file '' + @FileToDelete + '': '' + @ErrMsg;
				RAISERROR(@FullErrMsg, 16, 1);
			END CATCH

			DELETE FROM @Files WHERE subdirectory = @File;
		END 

		WHILE EXISTS(SELECT * FROM @Files f WHERE f.Processed = 0)
		BEGIN
			SELECT TOP 1 @File = subdirectory FROM @Files WHERE Processed = 0 ORDER BY subdirectory;

			PRINT ''Processing file: '' + @File;

			SET @SQL = N'''';

			SET @FileType = SUBSTRING(@File, LEN(@File) - 3, 4);

			IF @FileType = N''.bak''
			BEGIN
				IF EXISTS(SELECT * FROM @DBs WHERE DBName = @DBName)
				BEGIN
					PRINT N''Dropping '' + @DBName + N'' because a new full backup file was found.'';

					SET @SQL = N''
DROP DATABASE '' + QUOTENAME(@DBName) + N'';'';

					PRINT @SQL;
					IF @Debug = 0
						EXEC sp_ExecuteSQL @SQL;
				END 

				-- Find logical file names for MOVE statements
				SET @SQL = N''
RESTORE FILELISTONLY 
FROM DISK = '''''' + @SubFolder + N''\'' + @File + '''''';'';

				INSERT @FileListTable
				EXEC sp_ExecuteSQL @SQL;

				-- Generate restore script
				SET @SQL = N''
RESTORE DATABASE '' + QUOTENAME(@DBName) + N''
FROM DISK = '''''' + @SubFolder + N''\'' + @File + ''''''
WITH'';
 
				SELECT @SQL += N''
MOVE '''''' + f.LogicalName + N'''''' TO '''''' + CASE WHEN f.Type = ''D'' THEN @DataFilePath + N''\'' + @DBName + N''.mdf'' ELSE @LogFilePath + N''\'' + @DBName + N''.ldf'' END + '''''',''
				FROM @FileListTable f

				SET @SQL += N''
NORECOVERY;'';
			END -- Is file a .bak

			IF @FileType = N''.trn''
			BEGIN
				IF NOT EXISTS(SELECT * FROM @DBs WHERE DBName = @DBName)
				BEGIN
					SET @ErrMsg = ERROR_MESSAGE();
					SET @FullErrMsg = ''Failed to restore log for '' + ISNULL(@DBName, ''unknown database'') + '' because the database doesn''''t exist: '' + @ErrMsg;
					RAISERROR(@FullErrMsg, 16, 1);
				END 
				ELSE
				BEGIN
					SET @SQL = N''
RESTORE LOG '' + QUOTENAME(@DBName) + N''
FROM DISK = '''''' + @SubFolder + N''\'' + @File + N'''''''';

					IF @StandbyMode = 1
					BEGIN
						SET @SQL += N''
WITH STANDBY = '''''' + @SubFolder + N''\UNDO_'' + @DBName + N''.undo'''';'';
					END
					ELSE
					BEGIN
						SET @SQL += N''
WITH NORECOVERY;'';
					END
				END -- Database already exists
			END -- Is file a .bak
				
			BEGIN TRY
				IF @Error = 0
				BEGIN
					PRINT @SQL
					IF @Debug = 0
					BEGIN
						-- Restore file
						EXEC sp_ExecuteSQL @SQL;

						SET @FileToDelete = @SubFolder + N''\'' + @File

						PRINT N''Deleting '' + @File + N'' after restore'';
						EXEC xp_Delete_file 0, @FileToDelete;
					END

					-- If full backup restored, add it to the list of DBs on the server
					IF @FileType = N''.bak''
					BEGIN
						INSERT @DBs
						SELECT @DBName;
					END
				END
			END TRY
			BEGIN CATCH
				SET @Error = 1;
				SET @ErrMsg = ERROR_MESSAGE();
				SET @FullErrMsg = ''Failed to restore backup for '' + ISNULL(@DBName, ''unknown database'') + '': '' + @ErrMsg;
				RAISERROR(@FullErrMsg, 16, 1);
			END CATCH

			DELETE FROM @FileListTable

			UPDATE @Files SET Processed = 1 WHERE subdirectory = @File;
		END -- File loop
	END

	PRINT ''
===================='';

	UPDATE @Folders SET Processed = 1 WHERE subdirectory = @DBName;
END', 
		@database_name=N'master', 
		@output_file_name=N'N:\TestSQLLogShipping\Output\QA_LogShippingRestore_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
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
		@active_start_date=20170816, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'd5aa35b8-62ba-4a7f-902e-d640fb55d733'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO