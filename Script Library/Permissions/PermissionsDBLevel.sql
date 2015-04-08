
-- Database Principals
SELECT	DBPrincipals.name, 
		DBPrincipals.sid, 
		DBPrincipals.type, 
		DBPrincipals.type_desc,     
		DBPrincipals.default_schema_name, 
		DBPrincipals.create_date, 
		DBPrincipals.modify_date,    
		DBPrincipals.is_fixed_role, 
		Authorizations.name AS Role_Authorization,    
		CASE	
		WHEN DBPrincipals.is_fixed_role = 0 
		THEN 'DROP ' +	CASE DBPrincipals.[type]	WHEN 'C' THEN NULL                
													WHEN 'K' THEN NULL                
													WHEN 'R' THEN 'ROLE'                
													WHEN 'A' THEN 'APPLICATION ROLE'                
													ELSE 'USER' 
						END +            ' '+QUOTENAME(DBPrincipals.name) + ';' 
		ELSE NULL END AS Drop_Script,    
			CASE	WHEN DBPrincipals.is_fixed_role = 0 THEN 'CREATE ' + CASE DBPrincipals.[type] 
					WHEN 'C' THEN NULL                
					WHEN 'K' THEN NULL                
					WHEN 'R' THEN 'ROLE'                
					WHEN 'A' THEN 'APPLICATION ROLE'                
					ELSE 'USER' 
			END +            ' '+QUOTENAME(DBPrincipals.name) 
			END +            
			CASE	WHEN DBPrincipals.[type] = 'R' THEN ISNULL(' AUTHORIZATION '+QUOTENAME(Authorizations.name),'')                
					WHEN DBPrincipals.[type] = 'A' THEN                    ''                 
					WHEN DBPrincipals.[type] NOT IN ('C','K') THEN ISNULL(' FOR LOGIN ' + QUOTENAME(SrvPrincipals.name),' WITHOUT LOGIN') + ISNULL(' WITH DEFAULT_SCHEMA =  '+QUOTENAME(DBPrincipals.default_schema_name),'')            
					ELSE ''            
			END + ';'        AS Create_Script

FROM sys.database_principals DBPrincipals
LEFT OUTER JOIN sys.database_principals Authorizations    ON DBPrincipals.owning_principal_id = Authorizations.principal_id
LEFT OUTER JOIN sys.server_principals SrvPrincipals    ON DBPrincipals.sid = SrvPrincipals.sid    AND DBPrincipals.sid NOT IN (0x00, 0x01)

--WHERE DBPrincipals.name LIKE '%MyUserName%' 




-- Database & object Permissions
SELECT		Grantee.name AS Grantee_Name, 
			Grantor.name AS Grantor_Name,    
			Permission.class_desc, 
			Permission.permission_name,    
			[Objects].name AS ObjectName, 
			Permission.state_desc,     
			'REVOKE ' + CASE WHEN Permission.[state]  = 'W' THEN 'GRANT OPTION FOR ' 
						ELSE '' 
						END +    ' ' + Permission.permission_name COLLATE SQL_Latin1_General_CP437_CI_AS +	CASE WHEN Permission.major_id <> 0 THEN ' ON ' + QUOTENAME([Objects].name) + ' ' 
																											ELSE '' 
																											END +        ' FROM ' + QUOTENAME(Grantee.name)  + '; ' AS Revoke_Statement,    
			CASE WHEN Permission.[state]  = 'W' THEN 'GRANT' 
			ELSE Permission.state_desc COLLATE SQL_Latin1_General_CP437_CI_AS  
			END + ' ' + Permission.permission_name  + CASE	WHEN Permission.major_id <> 0 THEN ' ON ' + QUOTENAME([Objects].name) + ' ' 
															ELSE '' 
															END + ' TO ' + QUOTENAME(Grantee.name)  + ' ' +  CASE	WHEN Permission.[state]  = 'W' THEN ' WITH GRANT OPTION ' 
																													ELSE '' 
																													END + ' AS '+ QUOTENAME(Grantor.name)+';' AS Grant_Statement

FROM sys.database_permissions Permission
JOIN sys.database_principals Grantee ON Permission.grantee_principal_id = Grantee.principal_id
JOIN sys.database_principals Grantor ON Permission.grantor_principal_id = Grantor.principal_id
LEFT OUTER JOIN sys.all_objects [Objects] ON Permission.major_id = [Objects].object_id

--WHERE Grantee.name LIKE '%MyUserName%' 

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