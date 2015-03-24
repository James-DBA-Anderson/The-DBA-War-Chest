
-- DBA War Chest 
-- Show TempDB Contention (PFS, GAM or SGAM) 
-- 2015-03-24 

-- Show any contention in TempDB.
-- Adding extra data files to TempDB can aleviate contention in TempDB.
-- All data files should be equally sized and have the same growth rate.

SELECT		a.session_id,
			a.wait_type,
			a.wait_duration_ms,
			a.blocking_session_id,
			a.resource_description,
			CASE	WHEN CAST(RIGHT(a.resource_description, LEN(a.resource_description) - CHARINDEX(':', a.resource_description, 3)) AS INT) - 1 % 8088 = 0 THEN 'Is PFS Page'
					WHEN CAST(RIGHT(a.resource_description, LEN(a.resource_description) - CHARINDEX(':', a.resource_description, 3)) AS INT) - 2 % 511232 = 0 THEN 'Is GAM Page'
					WHEN CAST(RIGHT(a.resource_description, LEN(a.resource_description) - CHARINDEX(':', a.resource_description, 3)) AS INT) - 3 % 511232 = 0 THEN 'Is SGAM Page'
					ELSE 'Is Not PFS, GAM, or SGAM page'
			END resourcetype,
			c.text AS SQLText

FROM		sys.dm_os_waiting_tasks a
JOIN		sys.sysprocesses b ON a.session_id = b.spid
OUTER APPLY sys.dm_exec_sql_text(b.sql_handle) c

WHERE		a.wait_type LIKE 'PAGE%LATCH_%'
			AND a.resource_description LIKE '2:%';
