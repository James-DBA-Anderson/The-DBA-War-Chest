	DECLARE @SQL NVARCHAR(MAX), @DB NVARCHAR(100)

	DECLARE @DBs TABLE
	(DBName		NVARCHAR(100))

	DECLARE @Permissions TABLE
	([Database]		NVARCHAR(100)
	,[UserName]		NVARCHAR(200)
	,[UserType]		NVARCHAR(100)
	,FixedRole		NVARCHAR(3)
	,[ServerRole]	NVARCHAR(200)
	,[RoleType]		NVARCHAR(200)
	,[CreateDate]	DATETIME
	,[ModifiedDate]	DATETIME)

	INSERT INTO @DBs
	SELECT		name
	FROM		sys.databases
	WHERE		database_id > 4

	WHILE EXISTS(SELECT * FROM @DBs)
	BEGIN
		BEGIN TRY
			SELECT TOP 1 @DB = DBName FROM @DBs
			
			SET @SQL = ' 
						SELECT		''' + @DB + ''' AS [Database],
									p.name AS UserName, 
									p.type_desc AS UserType, 
									CASE WHEN p.is_fixed_role = 1 THEN ''Yes'' ELSE ''No'' END AS FixedRole,
									pp.name AS ServerRole, 
									pp.type_desc AS RoleType,
									p.create_date,
									p.modify_date
 
						FROM		[' + @DB + '].sys.database_role_members roles 
						JOIN		[' + @DB + '].sys.database_principals p ON roles.member_principal_id = p.principal_id 
						JOIN		[' + @DB + '].sys.database_principals pp ON roles.role_principal_id = pp.principal_id'			
			
			INSERT INTO @Permissions
			EXEC SP_ExecuteSql @SQLToExecute = @SQL
			
		END TRY
		BEGIN CATCH
			SELECT 'Failed to retrieve DB level permissions for ' + @DB + '. ' + ERROR_MESSAGE() + ' ' + @SQL
		END CATCH

		DELETE FROM @DBs WHERE DBName = @DB
	END

	SELECT		*

	FROM		@Permissions

	ORDER BY	[Database], UserName, RoleType, ServerRole