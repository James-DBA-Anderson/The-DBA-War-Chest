
-- DBA War Chest 
-- Page Life Expectancy 
-- 2015-03-31

-- Show the PLE of the server by NUMA node. This is a rough figure 
-- that represents the number of seconds pages stay in memory, the higher the better.


SELECT  OBJECT_NAME 
        , counter_name
        , instance_name AS [NUMA Node] 
        , cntr_value AS [value] 

FROM    sys.dm_os_performance_counters 


WHERE  	LTRIM(RTRIM(OBJECT_NAME)) LIKE '%Buffer Node' 
AND 	LTRIM(RTRIM(counter_name)) = 'Page life expectancy' ; 
