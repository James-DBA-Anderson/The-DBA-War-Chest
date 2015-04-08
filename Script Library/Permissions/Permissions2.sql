
select p.name, p.type_desc, pp.name, pp.type_desc
 
from  sys.server_role_members roles
 
join sys.server_principals p on roles.member_principal_id = p.principal_id
 
join sys.server_principals pp on roles.role_principal_id = pp.principal_id


SELECT
 
p.name, p.type_desc, pp.name, pp.type_desc, pp.is_fixed_role
 
FROM sys.database_role_members roles
 
JOIN sys.database_principals p ON roles.member_principal_id = p.principal_id
 
JOIN sys.database_principals pp ON roles.role_principal_id = pp.principal_id
