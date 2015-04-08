
-- DBA War Chest 
-- Logons Not Used
-- 2015-03-31

-- Show all logons that do not have access to a database.

DECLARE @user sysname;

DECLARE @uselessusers TABLE (name sysname NULL);

DECLARE cur CURSOR STATIC LOCAL FOR
    SELECT name FROM sys.server_principals
    WHERE  TYPE IN ('S', 'U');

OPEN cur;

WHILE 1 = 1
BEGIN
	FETCH cur INTO @user;
	IF @@fetch_status <> 0
		BREAK;

	BEGIN TRY
		EXECUTE AS LOGIN = @user;
	END TRY
	BEGIN CATCH
		PRINT 'Skipping user ' + @user + ': ' + ERROR_MESSAGE();
		CONTINUE;
	END CATCH;

	IF NOT EXISTS (SELECT *
					FROM   sys.databases
					WHERE  database_id >= 5
						AND  HAS_DBACCESS(name) = 1)
		INSERT @uselessusers(name) VALUES (@user);

	REVERT;
END;

CLOSE cur;

SELECT name FROM @uselessusers;
