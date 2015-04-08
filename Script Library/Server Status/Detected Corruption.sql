
-- DBA War Chest 
-- Show Detected Corruption 
-- 2015-03-13 

-- Show any corruption that the server has detected.

-- This is not a replacement for running DBCC CHECKDB 
-- as it will not detect corruption that is as of yet 
-- unknown to the server.


SELECT		* 

FROM		msdb.dbo.suspect_pages