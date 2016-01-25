
-- DBA War Chest 
-- Worker Threads
-- 2015-10-09

-- Show the work thread limit for each subsystem

select	subsystem, 
		RIGHT(subsystem_dll,20) as 'Agent DLL', 
		RIGHT(agent_exe,20) as 'Agent Exe', 
		max_worker_threads

from	msdb.dbo.syssubsystems

 