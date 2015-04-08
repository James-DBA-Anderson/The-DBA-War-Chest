
	
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
			,@DBList = 'Freightliner,AA,Admin,AegisMedia,AFBlakemore,Alere,Marshall,ASOS,Atradius,Barclays,TotalUK,BAT,BoAIE,BoAUK,BOC,BOCRoI,CAA,CCEBE,CCEFR,CCENL,CCENO,CCESE,CCEUK,CCEUS,Centrica,CSC,DeBeers,Demo,Demo14,Doosan,DST,DunAndBradstreet,Dune,EdfEnergy,EIML,Eon,Experian,ExperianRoadshow,Hastings,Hilti,HTC,Ingredion,Interserve,Kambi,Kenwood,Kraft,KraftROI,LSE,MarksAndSpencer,Marvellous,MBDA,Micheldever,MSD,NortonRoseFulbright,Novatech,Paramount,PensPen,PernodRicard,Philips,PLA,Reeves,Selfridges,Sky,SkyRoI,SSB,SSBCI,SSP,TeachFirst,TetraPakRoI,TetraPakUK,ThomsonReuters,TotalEP,TotalGP,TravelWeeklyGroup,TRW,Unisys,Viacom,Wates,Wolseley,LSL,RationalGroup,ERS,DemoAE,TotalLOR,ACCA,CeladorRadio,Nexen'
			,@UserList = 'SSRS,web_user,COMM\backup_user,COMM\Domain Admins,COMM\DrewClarke,COMM\DuaneJoubert,COMM\JamesAnderson,COMM\MatthewClarke,COMM\PaulMoody,COMM\queue_service,
							COMM\SimonPates,COMM\SQLAdmin,COMM\SQLAGTSVC,COMM\SQLDBSVC,COMM\SQLRepService,COMM\TonyBenham' -- White list of users to not alter permissions for
			,@RolesToRemove = 'db_owner,db_datawriter,db_securityadmin,db_accessadmin,db_backupoperator,db_ddladmin'

	---------------------------------

	SELECT	@DBList = '''' + REPLACE(@DBList, ',', ''',''') + ''''
			,@UserList = '''' + REPLACE(@UserList, ',', ''',''') + ''''
			,@RolesToRemove = '''' + REPLACE(@RolesToRemove, ',', ''',''') + ''''

	CREATE TABLE #DBs 
	(DBName		NVARCHAR(100),
	[Version]	NVARCHAR(20))

	CREATE TABLE #Permissions
	([Database]				NVARCHAR(100)
	,[Version]				NVARCHAR(20)
	,[UserName]				NVARCHAR(200)
	,[UserType]				NVARCHAR(100)
	,FixedRole				NVARCHAR(3)
	,[DatabaseRole]			NVARCHAR(200)
	,[RoleType]				NVARCHAR(200)
	,[CreateDate]			DATETIME
	,[ModifiedDate]			DATETIME
	,[RemovalResult]		NVARCHAR(MAX)
	,[StatementRan]			NVARCHAR(MAX)
	,[StatementToReplace]	NVARCHAR(MAX))

	INSERT INTO #DBs
	SELECT		DISTINCT d.name, ISNULL(s.[Version], 'NA')
	FROM		sys.databases d
	LEFT JOIN	[Admin]..Client c ON d.name = c.Name
	LEFT JOIN	[Admin]..[Site] s ON c.SiteId = s.SiteId
	WHERE		database_id > 4 
				--AND s.Version LIKE '14%' -- Version 14 DBs only

	PRINT 'Build list of permissions to remove'

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
									p.modify_date,
									NULL,
									NULL,
									NULL
 
						FROM		[' + @DB + '].sys.database_role_members roles 
						JOIN		[' + @DB + '].sys.database_principals p ON roles.member_principal_id = p.principal_id 
						JOIN		[' + @DB + '].sys.database_principals pp ON roles.role_principal_id = pp.principal_id
						
						WHERE		''' + @DB + ''' IN (' + @DBList + ')
									AND p.name NOT IN (' + @UserList + ')
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

	PRINT 'Start removing Permissions'

	WHILE EXISTS(	SELECT	* 
					FROM	#Permissions 
					WHERE	RemovalResult IS NULL
							AND UserName NOT IN ('dbo', 'web_test', 'web_user', 'BENEFEX\web_test', 'COMM\web_test')
				)
	BEGIN
		SELECT	TOP 1 @DB = [Database], @DatabaseRole = DatabaseRole, @User = UserName FROM	#Permissions 
		WHERE	RemovalResult IS NULL AND UserName NOT IN ('dbo', 'web_test', 'web_user', 'BENEFEX\web_test', 'COMM\web_test')

		BEGIN TRY
			SET @SQLRmvPermission = 'ALTER ROLE [' + @DatabaseRole + '] DROP MEMBER [' + @User + '];'

			SET @SQL = N'EXEC [' + @DB + ']..sp_executesql @SQLRmvPermission;'		
			
			IF @Debug = 0 -- If not in debug mode run the query to remove the permissions
				EXEC sp_executesql @SQL, N'@SQLRmvPermission NVARCHAR(MAX)', @SQLRmvPermission; 

			UPDATE #Permissions SET RemovalResult = 'Success', StatementRan = @SQLRmvPermission, StatementToReplace = 'USE [' + @DB + ']; ALTER ROLE [' + @DatabaseRole + '] ADD MEMBER [' + @User + '];' WHERE [Database] = @DB AND UserName = @User AND DatabaseRole = @DatabaseRole
		END TRY
		BEGIN CATCH
			SELECT 'Failed to remove permissions ' + @DatabaseRole + ' for ' + @User + ' on ' + @DB + '. ' + ERROR_MESSAGE() + ' ' + @SQL AS [Error]
			UPDATE #Permissions SET RemovalResult = 'Failed: ' + ERROR_MESSAGE() WHERE [Database] = @DB AND UserName = @User AND DatabaseRole = @DatabaseRole
		END CATCH		
	END


	IF @Debug = 0
	BEGIN
		BEGIN TRY
			INSERT INTO Maintenance.dbo.PermissionsRemoved
			SELECT		*, GETDATE()
			FROM		#Permissions
		END TRY
		BEGIN CATCH
			SELECT 'Failed to remove permissions ' + @DatabaseRole + ' for ' + @User + ' on ' + @DB + '. ' + ERROR_MESSAGE() + ' ' + @SQL AS [Error]
			DELETE FROM #Permissions WHERE [Database] = @DB AND UserName = @User AND DatabaseRole = @DatabaseRole
		END CATCH
	END

	-- Give a manual run an output
	SELECT		*
	FROM		#Permissions


	DROP TABLE #DBs
	DROP TABLE #Permissions
