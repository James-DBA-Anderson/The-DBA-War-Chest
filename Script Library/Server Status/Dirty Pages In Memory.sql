
-- DBA War Chest 
-- Dirty Pages In Memory
-- 2015-05-06

-- Show the count of dirty and clean pages in memory by database
-- This script was written by Paul Randal. See here for details: http://www.sqlskills.com/blogs/paul/when-dbcc-dropcleanbuffers-doesnt-work/

SELECT *,
    [DirtyPageCount] * 8 / 1024 AS [DirtyPageMB],
    [CleanPageCount] * 8 / 1024 AS [CleanPageMB]
FROM
    (SELECT
        (CASE WHEN ([database_id] = 32767)
            THEN N'Resource Database'
            ELSE DB_NAME ([database_id]) END) AS [DatabaseName], 
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 1 ELSE 0 END) AS [DirtyPageCount], 
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 0 ELSE 1 END) AS [CleanPageCount]
    FROM sys.dm_os_buffer_descriptors
    GROUP BY [database_id]) AS [buffers]
ORDER BY [DatabaseName]
GO 