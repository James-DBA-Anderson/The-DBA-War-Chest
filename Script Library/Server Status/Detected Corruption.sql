
-- DBA War Chest 
-- Show Detected Corruption 
-- 2015-03-13 

-- Show any corruption that the server has detected.

-- This is not a replacement for running DBCC CHECKDB 
-- as it will not detect corruption that is as of yet 
-- unknown to the server.


SELECT	d.name, sp.* 

FROM	sys.databases d
JOIN	msdb.dbo.suspect_pages sp ON d.database_id = sp.database_id 

order by last_update_date desc
