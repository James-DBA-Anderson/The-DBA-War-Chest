
-- DBA War Chest 
-- Instance Level Permissions
-- 2015-05-19

-- Show the logins for the instance that the user accounts in each database map to.
-- Databases using contained user accounts will not have corresponding logins here.

	SELECT		p.name AS UserName, 
				p.type_desc AS UserType, 
				CASE 
					WHEN p.is_disabled = 1 
					THEN 'Yes' 
				END AS [Disabled],
				pp.name AS ServerRole, 
				sl.SID,
				sl.password_hash,
				p.create_date AS CreateDate,
				p.modify_date AS ModifyDate

	FROM		sys.server_principals p  
	LEFT JOIN	sys.sql_logins sl ON sl.principal_id = p.principal_id	
	LEFT JOIN	sys.server_role_members rm ON p.principal_id = rm.member_principal_id
	LEFT JOIN	sys.server_principals pp ON rm.role_principal_id = pp.principal_id

	ORDER BY	p.name