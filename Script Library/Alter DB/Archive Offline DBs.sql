
-- DBA War Chest 
-- Archive Offline Databases
-- 2016-10-24

-- Set DBs that are believed to be nolonger required as offline. This allows for a fast recovery if it turns out they are required.
-- Once they have been offline for long enough to ensure they are not needed (1 week, 1 month?) this script will bring them
-- online, backups them up and the DROP them.

USE master;
GO

DECLARE @Error int = 0, @ReturnCode int, @ErrorMessage nvarchar(max)

-- Set variables --------------------------------------------------------

DECLARE		@BackupPath VARCHAR(1024) = 'D:\Archive', -- Folder path to store .bak fils.
			@DropDBs BIT = 1, 
			@ScriptOnly BIT = 1, -- Produce scripts for the work or run automatically.
			@ArchiveDate NVARCHAR(10) = CONVERT(NVARCHAR(10), GETDATE(), 112);

-- Sanitise Inputs ------------------------------------------------------		

IF @BackupPath NOT LIKE '%\'
BEGIN
	SET @BackupPath += '\';
END

IF @BackupPath IS NULL
BEGIN
	RAISERROR('@BackupPath can''t be NULL.', 16, 1) WITH NOWAIT;
    SET @Error = @@ERROR;
END

IF ((@BackupPath NOT LIKE '%\%') OR (@BackupPath NOT LIKE '%:%'))
BEGIN
	RAISERROR('@BackupPath is not a valid folder path.', 16, 1) WITH NOWAIT;
    SET @Error = @@ERROR;
END

IF @Error <> 0
BEGIN
	SET @ReturnCode = @Error;
	GOTO ReturnCode;
END

--------------------------------------------------------------------------

DECLARE @SQL NVARCHAR(MAX) = N'', @DBName SYSNAME = '', @AutoUpdateStatsAsync BIT = 0, @Online TINYINT = 6;

DECLARE @DBs TABLE (Name SYSNAME, AutoUpdateStatsAsync BIT, Processed BIT);

INSERT @DBs
SELECT name, is_auto_update_stats_async_on, 0
FROM sys.databases d
WHERE d.state_desc = 'Offline'
ORDER BY name;

WHILE EXISTS(SELECT 1 FROM @DBs WHERE processed = 0)
BEGIN
	BEGIN TRY
		SELECT TOP 1 @DBName = Name, @AutoUpdateStatsAsync = AutoUpdateStatsAsync, @Online = 6 FROM @DBs WHERE Processed = 0 ORDER BY Name;

		SET @SQL = N'
ALTER DATABASE ' + QUOTENAME(@DBName) + N'
SET ONLINE;';

		IF @ScriptOnly = 1
		BEGIN
			PRINT @SQL;
		END ELSE
		BEGIN
			EXEC sp_ExecuteSQL @SQL;
		END

		SET @SQL = N'
ALTER DATABASE ' + QUOTENAME(@DBName) + N'
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;';

		IF @ScriptOnly = 1
		BEGIN
			PRINT @SQL;
		END ELSE
		BEGIN
			EXEC sp_ExecuteSQL @SQL;
		END

		IF @ScriptOnly = 0
		BEGIN		
			WHILE @Online = 6
			BEGIN
				SET @ErrorMessage = 'Waiting for ' + @DBName + ' to come online...';
				RAISERROR(@ErrorMessage, 1, 1) WITH NOWAIT;
				WAITFOR DELAY '00:00:01';
				SET @Online = (SELECT d.state FROM sys.databases d WHERE name = @DBName);
			END
		END

		IF (@AutoUpdateStatsAsync = 1) 
		BEGIN
			SET @SQL = N'
ALTER DATABASE ' + QUOTENAME(@DBName) + N' SET AUTO_UPDATE_STATISTICS_ASYNC OFF;';

			IF @ScriptOnly = 1
			BEGIN
				PRINT @SQL;
			END ELSE
			BEGIN
				EXEC sp_ExecuteSQL @SQL;
			END
		END

		SET @SQL = N'
BACKUP DATABASE ' + QUOTENAME(@DBName) + N'
TO DISK = ''' + @BackupPath + @DBName + N'_Archived_' + @ArchiveDate + N'.bak''
WITH COMPRESSION;';

		IF @ScriptOnly = 1
		BEGIN
			PRINT @SQL;
		END ELSE
		BEGIN
			EXEC sp_ExecuteSQL @SQL;
		END

		IF @DropDBs = 1
		BEGIN			
			SET @SQL = N'
DROP DATABASE ' + QUOTENAME(@DBName) + N';';

			IF @ScriptOnly = 1
			BEGIN
				PRINT @SQL;
			END ELSE
			BEGIN
				PRINT 'Dropping ' + @DBName + '...';
				EXEC sp_ExecuteSQL @SQL;
				PRINT 'Dropped ' + @DBName;
			END
		END

		UPDATE @DBs SET Processed = 1 WHERE Name = @DBName;
	END TRY
	BEGIN CATCH
		UPDATE @DBs SET Processed = 1 WHERE Name = @DBName;

		SET @ErrorMessage = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage, 16, 1) WITH NOWAIT;
	END CATCH
END;

ReturnCode:
IF @ReturnCode <> 0
BEGIN
	SELECT @ReturnCode AS ReturnCode
END