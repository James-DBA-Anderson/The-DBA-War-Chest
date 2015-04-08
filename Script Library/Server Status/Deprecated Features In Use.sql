
-- DBA War Chest 
-- Deprecated Features in Use 
-- 2015-03-24

-- Display how many times deprecated features have been used


SELECT		* 

FROM		sys.dm_os_performance_counters

WHERE		object_name LIKE '%Deprecated Features%'
			AND cntr_value > 0

ORDER BY	cntr_value DESC
