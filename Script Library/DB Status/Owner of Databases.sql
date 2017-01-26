
-- Written by Andreas Wolter
-- Code taken from https://gallery.technet.microsoft.com/scriptcenter/Database-Owners-role-3af181f5/

/* Note: 
 
You need to be a member of the sysadmin-role to run this script 
*/ 
 
SET NOCOUNT ON; 
 
USE Tempdb; 
 
CREATE TABLE #DatabaseOwners 
( 
       dbname               sysname        NOT NULL 
    ,   matched_owner       nvarchar(128)   NULL 
); 
 
INSERT INTO #DatabaseOwners 
EXEC sp_MSforeachdb 'SELECT          ''?''          AS dbname 
       ,   SUSER_SNAME(database_principals.sid)      AS matched_owner 
FROM  [?].sys.database_principals 
WHERE  database_principals.name = ''dbo'' 
'; 
 
WITH Database_Owners_Principals 
AS 
( 
    SELECT 
          dbname 
       ,      database_id 
       ,   server_principals.principal_id 
       ,      server_principals.name     AS principal_name 
       ,   matched_owner 
       ,   is_trustworthy_on 
       ,   is_db_chaining_on 
    FROM #DatabaseOwners       AS DatabaseOwners 
    LEFT JOIN sys.databases       AS databases 
       ON DatabaseOwners.dbname = databases.name 
    LEFT OUTER JOIN sys.server_principals    AS server_principals 
       ON databases.owner_sid = server_principals.sid 
) 
,   Principals_Permissions 
AS 
( 
    SELECT  
          name 
       ,   grantee_principal_id 
       ,   server_permissions.type     AS permission_type 
       ,   server_principals.type        AS principal_type 
    FROM sys.server_permissions         AS server_permissions 
        INNER JOIN sys.server_principals     AS server_principals 
       ON server_permissions.grantee_principal_id = server_principals.principal_id 
    WHERE          server_permissions.type IN('CL', 'ALLG', 'ALSR', 'XA') 
       AND          state = 'G' 
       AND          server_principals.type IN ('R', 'S', 'U') 
) 
,   Roles_Permissions 
AS 
( 
    SELECT  
          grantee_principal_id 
       ,   server_permissions.type    AS permission_type 
       ,      server_principals.name        AS server_principal_name 
    FROM sys.server_permissions         AS server_permissions 
    INNER JOIN sys.server_principals     AS server_principals 
       ON server_permissions.grantee_principal_id = server_principals.principal_id 
    WHERE 
          server_permissions.type IN ('CL', 'ALLG', 'ALSR', 'XA') 
       AND 
          state = 'G'     
) 
SELECT   
    'db_' + CAST(RANK() OVER ( ORDER BY database_id) AS varchar(4))  AS DB# 
    ,   is_trustworthy_on                                AS is_trustworthy 
    ,   is_db_chaining_on                                AS db_chaining_on 
    ,   (SELECT ISNULL(COALESCE(NULLIF(value, 0), NULLIF(value_in_use, 0)), 0) FROM sys.configurations WHERE name = 'cross db ownership chaining')                                AS x_dbc 
    ,   CASE WHEN (Database_Owners_Principals.matched_owner IS NULL) THEN 'not valid (!)' 
          ELSE 'valid' END                                AS db_owner_valid 
    ,   CASE WHEN (Database_Owners_Principals.principal_id = 1)                THEN 'sa'              
            WHEN (Database_Owners_Principals.principal_name IS NULL) THEN 'Windows Group'             
            ELSE 'other account' 
          END                                        AS external_owner 
    ,   CASE WHEN (Database_Owners_Principals.principal_name IS NULL) THEN 'not checked' 
        ELSE Principals_Permissions.permission_type    END            AS login_permission 
 
    ,   CASE 
          WHEN (server_role_members.role_principal_id = 3) THEN 'sysadmin (!)' 
              WHEN (server_role_members.role_principal_id = 4) THEN 'securityadmin (!)' 
              WHEN (server_role_members.role_principal_id = 5) THEN 'serveradmin' 
              WHEN (server_role_members.role_principal_id = 6) THEN 'setupadmin' 
              WHEN (server_role_members.role_principal_id = 7) THEN 'processadmin' 
              WHEN (server_role_members.role_principal_id = 8) THEN 'diskadmin' 
           WHEN (server_role_members.role_principal_id = 9) THEN 'dbcreator' 
          WHEN (server_role_members.role_principal_id = 10) THEN 'bulkadmin' 
              WHEN (server_role_members.role_principal_id BETWEEN 4 AND 10) THEN 'other builtin server role' 
              WHEN (server_role_members.role_principal_id > 10) THEN 'custom server role' 
 
            WHEN (Database_Owners_Principals.principal_name IS NULL) THEN 'Windows Group' 
 
       ELSE NULL 
       END AS server_role_membership 
    ,   CASE WHEN (Database_Owners_Principals.principal_name IS NULL) THEN 'not checked' 
        ELSE Roles_Permissions.permission_type    END            AS role_permission 
 
    -- leave those columns out before submitting for anonymization: 
    ,   '|*cut here|'                                            AS [*internal details:] 
    ,   dbname                                            AS [*Database_Name] 
    ,   CASE WHEN (Database_Owners_Principals.principal_name IS NULL) THEN 'Windows Group: ' + Database_Owners_Principals.matched_owner + ' - Check permission paths with xp_logininfo' ELSE Database_Owners_Principals.principal_name END                AS [*External_Owner] 
    ,   CASE WHEN (Database_Owners_Principals.principal_name IS NULL) THEN 'not checked' 
        ELSE Roles_Permissions.server_principal_name    END            AS [*Custom_Role_Name] 
 
FROM Database_Owners_Principals 
LEFT JOIN Principals_Permissions 
    ON Database_Owners_Principals.principal_id = Principals_Permissions.grantee_principal_id 
LEFT JOIN sys.server_role_members     AS server_role_members 
    ON Database_Owners_Principals.principal_id = server_role_members.member_principal_id 
LEFT JOIN Roles_Permissions     AS Roles_Permissions 
    ON server_role_members.role_principal_id = Roles_Permissions.grantee_principal_id 
ORDER BY database_id ASC       -- just to make sure systemdatabases are always on top 
; 
GO 
 
DROP TABLE #DatabaseOwners; 
 
SET NOCOUNT OFF; 