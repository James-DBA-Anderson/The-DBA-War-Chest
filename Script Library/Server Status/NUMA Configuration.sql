-- Balancing your available SQL Server core licenses evenly across two NUMA nodes
-- Glenn Berry
-- SQLskills.com


-- Get socket, physical core and logical core count from SQL Server Error Log
EXEC sys.xp_readerrorlog 0, 1, N'detected', N'socket';


-- SQL Server NUMA node information 
SELECT node_id, node_state_desc, memory_node_id, processor_group, online_scheduler_count, 
       active_worker_count, avg_load_balance, resource_monitor_state
FROM sys.dm_os_nodes WITH (NOLOCK) 
WHERE node_state_desc <> N'ONLINE DAC' OPTION (RECOMPILE);


-- SQL Server schedulers by NUMA node
SELECT parent_node_id, 
  SUM(current_tasks_count) AS [current_tasks_count], 
  SUM(runnable_tasks_count) AS [runnable_tasks_count], 
  SUM(active_workers_count) AS [active_workers_count], 
  AVG(load_factor) AS avg_load_factor
FROM sys.dm_os_schedulers WITH (NOLOCK) 
WHERE [status] = N'VISIBLE ONLINE'
GROUP BY parent_node_id;



-- SQL Server NUMA node and cpu_id information
SELECT parent_node_id, scheduler_id, cpu_id
FROM sys.dm_os_schedulers WITH (NOLOCK) 
WHERE [status] = N'VISIBLE ONLINE';

-- If you have CPUs that spread cores over more then 4 sockets or 32 cores then some rebalancing is required.
-- http://www.sqlskills.com/blogs/glenn/balancing-your-available-sql-server-core-licenses-evenly-across-numa-nodes/
-- Fixing the problem

-- Unfortunately, this does not work, due to the license limits in SQL 2012/2014 Standard Edition
--ALTER SERVER CONFIGURATION SET PROCESS AFFINITY NUMANODE = 0,1;

-- Msg 5833, Level 16, State 2, Line 7
-- The affinity mask specified is greater than the number of CPUs supported or licensed on this edition of SQL Server.


-- This command spreads your available 32 logical core licenses across two NUMA nodes 
-- This is valid for an Intel processor, with HT enabled
-- ALTER SERVER CONFIGURATION
-- SET PROCESS AFFINITY CPU = 0 TO 15, 25 TO 40;