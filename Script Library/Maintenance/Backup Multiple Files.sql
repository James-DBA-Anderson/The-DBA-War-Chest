
--TODO: Think of a good way to replace the paths so they match the detination server.
--		Also make into two separate scripts as the restore function needs the .bak files to exist

DECLARE @SQL NVARCHAR(MAX) = '', @Database NVARCHAR(256), @BackupSegment NVARCHAR(2048)

DECLARE @BackupFiles TABLE
(FileNameAndPath NVARCHAR(MAX)
,Processed BIT)

-- Set variables -----------------------
USE DB-Name

SELECT @Database = DB_NAME() -- Use current database

INSERT INTO @BackupFiles
SELECT 'D:\backup\' + @Database + '_1.bak', 0
UNION
SELECT 'D:\backup\' + @Database + '_2.bak', 0
UNION
SELECT 'D:\backup\' + @Database + '_3.bak', 0
UNION
SELECT 'D:\backup\' + @Database + '_4.bak', 0
----------------------------------------

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


SET @SQL = 'BACKUP DATABASE [' + @Database + ']
'

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
 