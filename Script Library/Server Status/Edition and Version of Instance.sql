
-- DBA War Chest 
-- Edition and version of SQL instance
-- 2016-06-29

SELECT  
SERVERPROPERTY('ProductVersion') AS ProductVersion,  
SERVERPROPERTY('ProductLevel') AS ProductLevel,  
SERVERPROPERTY('Edition') AS Edition,  
SERVERPROPERTY('EngineEdition') AS EngineEdition;  
GO  