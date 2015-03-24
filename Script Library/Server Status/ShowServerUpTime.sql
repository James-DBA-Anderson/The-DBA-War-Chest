
-- DBA War Chest 
-- Show Server Up Time
-- 2015-03-13 

-- Show the number of days the server has been running for since it's last restart.
-- TODO: Add years, months, weeks, minutes and seconds.

SELECT	DATEDIFF(DAY, login_time, getdate()) UpDays
FROM	master..sysprocesses 
WHERE	spid = 1