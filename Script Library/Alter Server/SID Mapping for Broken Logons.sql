
-- DBA War Chest 
-- SPID Mapping for Broken Logons
-- 2015-03-31

-- Remap the SPIDs for logons in databases who do not match the SPID 
-- of the matching logon at the server level.

DECLARE @SQL NVARCHAR(MAX), @Database NVARCHAR(MAX), @Databases VARCHAR (MAX) = ''

DECLARE @DBs TABLE
(DBName NVARCHAR(100))

SELECT @Databases = COALESCE (	CASE WHEN @Databases = '' THEN name
								ELSE @Databases + ',' + name 
								END,'')

FROM sys.databases 

WHERE database_id > 4 AND name NOT LIKE '%$%'


SET @SQL = 'SELECT ''' + REPLACE(@Databases, ',', ''' UNION SELECT ''') + ''''

INSERT INTO @DBs
EXEC SP_EXECuteSql @SQLToEXECute = @SQL

DECLARE @Logins TABLE
(DB			VARCHAR(100)
,UserName	SYSNAME
,UserSID	VARBINARY(85))

DECLARE @TempLogins TABLE
(UserName	SYSNAME
,UserSID	VARBINARY(85))

---
WHILE EXISTS(SELECT 1 FROM @DBs)
BEGIN
	SET @Database = (SELECT TOP 1 DBName FROM @DBs)

	PRINT 'Checking ' + @Database
	SET @SQL = 'EXEC [' + @Database + ']..sp_change_users_login @Action=''Report'' '
	
	DELETE FROM @TempLogins
	INSERT INTO @TempLogins
	EXEC SP_EXECuteSql @SQLToEXECute = @SQL

	INSERT INTO @Logins
	SELECT @Database, l.*
	FROM @TempLogins l

	DELETE FROM @DBs WHERE DBName = @Database
END

DECLARE @User NVARCHAR(100)

WHILE EXISTS(SELECT * FROM @Logins)
BEGIN
	SELECT TOP 1 @Database = DB, @User = UserName FROM @Logins
	
	SET @SQL = 'EXEC [' + @Database + ']..sp_change_users_login @Action=''Auto_fix'', @UserNamePattern = ''' + @User + ''' '

	BEGIN TRY
		EXEC SP_EXECuteSql @SQLToEXECute = @SQL
		PRINT 'Mapped ' + @User + ' in ' + @Database
	END TRY
	BEGIN Catch
		PRINT 'Failed to map ' + @User + ' in ' + @Database
	END Catch

	DELETE FROM @Logins WHERE DB = @Database AND UserName = @User
END

