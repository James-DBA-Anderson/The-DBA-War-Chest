
-- DBA War Chest 
-- Memory Usage
-- 2016-04-14

-- Show how much memory each SQL Server processes is using

-- See here for details on the results https://msdn.microsoft.com/en-us/library/ms175019.aspx

SELECT	pages_kb / 1024.0 / 1024.0 AS MemUsageGB, * 

FROM	sys.dm_os_memory_clerks 

ORDER BY (pages_kb + awe_allocated_kb) desc

-- SQL Server 2008 + 2008R2 ORDER BY
-- ORDER BY (single_pages_kb + multi_pages_kb + awe_allocated_kb) desc


-- Non Microsoft modules loaded into SQL Server that could be using memory

SELECT	* 
FROM	sys.dm_os_loaded_modules 
WHERE	ISNULL(company, '') <> 'microsoft corporation'