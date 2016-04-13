
-- DBA War Chest 
-- Version Store Usage
-- 2016-04-13

-- Show TempDB version store usage on the current instance
-- see https://technet.microsoft.com/en-us/library/cc966545.aspx#EDAA for details on the results.
-- Scripts created by Max Vernon http://goo.gl/yNy20Y


SELECT	*
FROM	sys.dm_os_performance_counters dopc
WHERE	dopc.counter_name LIKE 'Version %';