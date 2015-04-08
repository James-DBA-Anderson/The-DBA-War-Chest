
-- DBA War Chest 
-- Show Available Disk Space
-- 2015-03-25

-- Show currently available diskspace on any disk used for 
-- SQL-Server data files on the current server.


SELECT		DISTINCT dovs.logical_volume_name AS LogicalName
			, dovs.volume_mount_point AS Drive
			, Round(Cast(CONVERT(INT,dovs.available_bytes/1048576.0) as float)/1024,2) AS FreeSpaceInGB

FROM		sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs

ORDER BY	FreeSpaceInGB ASC

