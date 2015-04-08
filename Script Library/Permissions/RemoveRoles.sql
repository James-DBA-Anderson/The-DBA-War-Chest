	
	-- Remove DB Level Permissions 
	-- James Anderson
	-- 2014-08-24

	-- This will not remove server or object level permissions
	-- This will not remove permissions for dbo, web_test or web_user 
	-- This will not remove any permissions while in debug mode
	-- This will not remove any permissions on system DBs
	
	DECLARE @Debug INT = 1, @DBList NVARCHAR(MAX), @UserList NVARCHAR(MAX), @RolesToRemove NVARCHAR(MAX), @SQL NVARCHAR(MAX), @DB NVARCHAR(100), 
			@Version NVARCHAR(100), @SQLRmvPermission NVARCHAR(MAX), @DatabaseRole NVARCHAR(50), @User NVARCHAR(200)

	-- Set Vars ---------------------

	SELECT	@Debug = 1 -- 1 = Debug mode, 0 = Live mode
			,@DBList = 'Admin'
			,@UserList = 'BENEFEX\anthonystevens'
			,@RolesToRemove = 'db_owner,db_datawriter'

	---------------------------------

	SELECT	@DBList = '''' + REPLACE(@DBList, ',', ''',''') + ''''
			,@UserList = '''' + REPLACE(@UserList, ',', ''',''') + ''''
			,@RolesToRemove = '''' + REPLACE(@RolesToRemove, ',', ''',''') + ''''

	CREATE TABLE #DBs 
	(DBName		NVARCHAR(100),
	[Version]	NVARCHAR(20))

	CREATE TABLE #Permissions
	([Database]		NVARCHAR(100)
	,[Version]		NVARCHAR(20)
	,[UserName]		NVARCHAR(200)
	,[UserType]		NVARCHAR(100)
	,FixedRole		NVARCHAR(3)
	,[DatabaseRole]	NVARCHAR(200)
	,[RoleType]		NVARCHAR(200)
	,[CreateDate]	DATETIME
	,[ModifiedDate]	DATETIME)

	INSERT INTO #DBs
	SELECT		DISTINCT d.name, ISNULL(s.[Version], 'NA')
	FROM		sys.databases d
	LEFT JOIN	[Admin]..Client c ON d.name = c.Name
	LEFT JOIN	[Admin]..[Site] s ON c.SiteId = s.SiteId
	WHERE		database_id > 4 
				--AND s.Version LIKE '14%' -- Version 14 DBs only

	WHILE EXISTS(SELECT * FROM #DBs)
	BEGIN
		BEGIN TRY
			SELECT TOP 1 @DB = DBName, @Version = ISNULL([Version], '') FROM #DBs
			
			SET @SQL = ' 
						SELECT		''' + @DB + ''' AS [Database],
									''' + @Version + ''' AS [Version],
									p.name AS UserName, 
									p.type_desc AS UserType, 
									CASE WHEN p.is_fixed_role = 1 THEN ''Yes'' ELSE ''No'' END AS FixedRole,
									pp.name AS DatabaseRole, 
									pp.type_desc AS RoleType,
									p.create_date,
									p.modify_date
 
						FROM		[' + @DB + '].sys.database_role_members roles 
						JOIN		[' + @DB + '].sys.database_principals p ON roles.member_principal_id = p.principal_id 
						JOIN		[' + @DB + '].sys.database_principals pp ON roles.role_principal_id = pp.principal_id
						
						WHERE		''' + @DB + ''' IN (' + @DBList + ')
									AND p.name IN (' + @UserList + ')
									AND pp.name IN (' + @RolesToRemove + ')'			
			
			INSERT INTO #Permissions
			EXEC SP_ExecuteSql @SQLToExecute = @SQL

			DELETE FROM #DBs WHERE DBName = @DB
		END TRY
		BEGIN CATCH
			SELECT 'Failed to retrieve DB level permissions for ' + @DB + '. ' + ERROR_MESSAGE() + ' ' + @SQL AS [Error]
			DELETE FROM #DBs WHERE DBName = @DB
		END CATCH
	END

	SELECT		*
	FROM		#Permissions
	ORDER BY	[Database], UserName, RoleType, DatabaseRole

	WHILE EXISTS(	SELECT	* 
					FROM	#Permissions 
					WHERE	UserName NOT IN ('dbo', 'web_test', 'web_user')
				)
	BEGIN
		SELECT	TOP 1 @DB = [Database], @DatabaseRole = DatabaseRole, @User = UserName FROM	#Permissions 
		WHERE	UserName NOT IN ('dbo', 'web_test', 'web_user')

		BEGIN TRY
			SET @SQLRmvPermission = 'ALTER ROLE [' + @DatabaseRole + '] DROP MEMBER [' + @User + '];'

			SET @SQL = N'EXEC [' + @DB + ']..sp_executesql @SQLRmvPermission;'		
			
			IF @Debug = 0 -- If not in debug mode run the query to remove the permissions
				EXEC sp_executesql @SQL, N'@SQLRmvPermission NVARCHAR(MAX)', @SQLRmvPermission;
			
			IF @Debug = 1
				SELECT @SQLRmvPermission AS [SQL]
		END TRY
		BEGIN CATCH
			SELECT 'Failed to remove permissions ' + @DatabaseRole + ' for ' + @User + ' on ' + @DB + '. ' + ERROR_MESSAGE() + ' ' + @SQL AS [Error]
			DELETE FROM #Permissions WHERE [Database] = @DB AND UserName = @User AND DatabaseRole = @DatabaseRole
		END CATCH

		DELETE FROM #Permissions WHERE [Database] = @DB AND UserName = @User AND DatabaseRole = @DatabaseRole
	END

	DROP TABLE #DBs
	DROP TABLE #Permissions