	
	USE [EM_OLL_OLTP]
	
	DECLARE @SQL NVARCHAR(MAX), @DB NVARCHAR(100)

	DECLARE @Permissions TABLE
	([Database]		NVARCHAR(100)
	,[UserName]		NVARCHAR(200)
	,[UserType]		NVARCHAR(100)
	,[ServerRole]	NVARCHAR(200)
	,[RoleType]		NVARCHAR(200)
	,[CreateDate]	DATETIME
	,[ModifiedDate]	DATETIME)

	-- Instance Level Permissions 
	SELECT		p.name AS UserName, 
				p.type_desc AS UserType, 
				CASE 
					WHEN p.is_disabled = 1 
					THEN 'Yes' 
				END AS [Disabled],
				pp.name AS ServerRole, 
				pp.type_desc AS RoleType,
				p.create_date AS CreateDate,
				p.modify_date AS ModifyDate
 
	FROM		sys.server_role_members roles 
	JOIN		sys.server_principals p ON roles.member_principal_id = p.principal_id 
	JOIN		sys.server_principals pp ON roles.role_principal_id = pp.principal_id

	ORDER BY	p.name

	-- Database Level Permissions
	SET @DB = DB_NAME()

	SELECT @DB

	BEGIN TRY
			
		SET @SQL = ' 
					SELECT		''' + @DB + ''' AS [Database],
								p.name AS UserName, 
								p.type_desc AS UserType, 
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

	-- Object Level Permissions
	SELECT		*

	FROM		@Permissions

	ORDER BY	[Database], UserName, RoleType, ServerRole


	SELECT		Grantee.name AS Grantee_Name, 
				Grantor.name AS Grantor_Name,    
				Permission.class_desc, 
				Permission.permission_name,    
				[Objects].name AS ObjectName, 
				Permission.state_desc

	FROM sys.database_permissions Permission
	JOIN sys.database_principals Grantee ON Permission.grantee_principal_id = Grantee.principal_id
	JOIN sys.database_principals Grantor ON Permission.grantor_principal_id = Grantor.principal_id
	LEFT OUTER JOIN sys.all_objects [Objects] ON Permission.major_id = [Objects].object_id

	WHERE Grantee.name <> 'public' 

	Order by 1