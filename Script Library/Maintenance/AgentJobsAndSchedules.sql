
-- DBA War Chest 
-- SQL Agent Jobs and Schedules 
-- 2015-03-30

-- Show all SQL Agent jobs with their schedules and longest run time.

USE msdb
GO;

SELECT			dbo.sysjobs.Name AS 'Job Name', 
				'Job Enabled' = CASE dbo.sysjobs.Enabled
					WHEN 1 THEN 'Yes'
					WHEN 0 THEN 'No'
				END,
				'Frequency' = CASE dbo.sysschedules.freq_type
					WHEN 1 THEN 'Once'
					WHEN 4 THEN 'Daily'
					WHEN 8 THEN 'Weekly'
					WHEN 16 THEN 'Monthly'
					WHEN 32 THEN 'Monthly relative'
					WHEN 64 THEN 'When SQLServer Agent starts'
				END, 
				'Start Date' = CASE active_start_date
					WHEN 0 THEN null
					ELSE
					SUBSTRING(CONVERT(VARCHAR(15),active_start_date),1,4) + '/' + 
					SUBSTRING(CONVERT(VARCHAR(15),active_start_date),5,2) + '/' + 
					SUBSTRING(CONVERT(VARCHAR(15),active_start_date),7,2)
				END,
				'Start Time' = CASE len(active_start_time)
					WHEN 1 THEN CAST('00:00:0' + RIGHT(active_start_time,2) AS CHAR(8))
					WHEN 2 THEN CAST('00:00:' + RIGHT(active_start_time,2) AS CHAR(8))
					WHEN 3 THEN CAST('00:0' 
							+ LEFT(RIGHT(active_start_time,3),1)  
							+':' + RIGHT(active_start_time,2) AS CHAR (8))
					WHEN 4 THEN CAST('00:' 
							+ LEFT(RIGHT(active_start_time,4),2)  
							+':' + RIGHT(active_start_time,2) AS CHAR (8))
					WHEN 5 THEN CAST('0' 
							+ LEFT(RIGHT(active_start_time,5),1) 
							+':' + LEFT(RIGHT(active_start_time,4),2)  
							+':' + RIGHT(active_start_time,2) AS CHAR (8))
					WHEN 6 THEN CAST(LEFT(RIGHT(active_start_time,6),2) 
							+':' + LEFT(RIGHT(active_start_time,4),2)  
							+':' + RIGHT(active_start_time,2) AS CHAR (8))
				END,
			--	active_start_time AS 'Start Time',
				CASE len(run_duration)
					WHEN 1 THEN CAST('00:00:0'
							+ CAST(run_duration AS CHAR) AS CHAR (8))
					WHEN 2 THEN CAST('00:00:'
							+ CAST(run_duration AS CHAR) AS CHAR (8))
					WHEN 3 THEN CAST('00:0' 
							+ LEFT(RIGHT(run_duration,3),1)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
					WHEN 4 THEN CAST('00:' 
							+ LEFT(RIGHT(run_duration,4),2)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
					WHEN 5 THEN CAST('0' 
							+ LEFT(RIGHT(run_duration,5),1) 
							+':' + LEFT(RIGHT(run_duration,4),2)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
					WHEN 6 THEN CAST(LEFT(RIGHT(run_duration,6),2) 
							+':' + LEFT(RIGHT(run_duration,4),2)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
				END AS 'MAX Duration',
				CASE(dbo.sysschedules.freq_subday_interval)
					WHEN 0 THEN 'Once'
					ELSE CAST('Every ' 
							+ RIGHT(dbo.sysschedules.freq_subday_interval,2) 
							+ ' '
							+     CASE(dbo.sysschedules.freq_subday_type)
										WHEN 1 THEN 'Once'
										WHEN 4 THEN 'Minutes'
										WHEN 8 THEN 'Hours'
									END AS CHAR(16))
				END AS 'Subday Frequency'

FROM			dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN		dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN	(SELECT		job_id
							, MAX(run_duration) AS run_duration

				FROM		dbo.sysjobhistory

				GROUP BY	job_id) Q1 ON dbo.sysjobs.job_id = Q1.job_id

WHERE			Next_run_time = 0

UNION

SELECT			dbo.sysjobs.Name AS 'Job Name', 
				'Job Enabled' = CASE dbo.sysjobs.Enabled
					WHEN 1 THEN 'Yes'
					WHEN 0 THEN 'No'
				END,
				'Frequency' = CASE dbo.sysschedules.freq_type
					WHEN 1 THEN 'Once'
					WHEN 4 THEN 'Daily'
					WHEN 8 THEN 'Weekly'
					WHEN 16 THEN 'Monthly'
					WHEN 32 THEN 'Monthly relative'
					WHEN 64 THEN 'When SQLServer Agent starts'
				END, 
				'Start Date' = CASE next_run_date
					WHEN 0 THEN null
					ELSE
					SUBSTRING(CONVERT(VARCHAR(15),next_run_date),1,4) + '/' + 
					SUBSTRING(CONVERT(VARCHAR(15),next_run_date),5,2) + '/' + 
					SUBSTRING(CONVERT(VARCHAR(15),next_run_date),7,2)
				END,
				'Start Time' = CASE len(next_run_time)
					WHEN 1 THEN CAST('00:00:0' + RIGHT(next_run_time,2) AS CHAR(8))
					WHEN 2 THEN CAST('00:00:' + RIGHT(next_run_time,2) AS CHAR(8))
					WHEN 3 THEN CAST('00:0' 
							+ LEFT(RIGHT(next_run_time,3),1)  
							+':' + RIGHT(next_run_time,2) AS CHAR (8))
					WHEN 4 THEN CAST('00:' 
							+ LEFT(RIGHT(next_run_time,4),2)  
							+':' + RIGHT(next_run_time,2) AS CHAR (8))
					WHEN 5 THEN CAST('0' + LEFT(RIGHT(next_run_time,5),1) 
							+':' + LEFT(RIGHT(next_run_time,4),2)  
							+':' + RIGHT(next_run_time,2) AS CHAR (8))
					WHEN 6 THEN CAST(LEFT(RIGHT(next_run_time,6),2) 
							+':' + LEFT(RIGHT(next_run_time,4),2)  
							+':' + RIGHT(next_run_time,2) AS CHAR (8))
				END,
			--	next_run_time AS 'Start Time',
				CASE len(run_duration)
					WHEN 1 THEN CAST('00:00:0'
							+ CAST(run_duration AS CHAR) AS CHAR (8))
					WHEN 2 THEN CAST('00:00:'
							+ CAST(run_duration AS CHAR) AS CHAR (8))
					WHEN 3 THEN CAST('00:0' 
							+ LEFT(RIGHT(run_duration,3),1)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
					WHEN 4 THEN CAST('00:' 
							+ LEFT(RIGHT(run_duration,4),2)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
					WHEN 5 THEN CAST('0' 
							+ LEFT(RIGHT(run_duration,5),1) 
							+':' + LEFT(RIGHT(run_duration,4),2)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
					WHEN 6 THEN CAST(LEFT(RIGHT(run_duration,6),2) 
							+':' + LEFT(RIGHT(run_duration,4),2)  
							+':' + RIGHT(run_duration,2) AS CHAR (8))
				END AS 'MAX Duration',
				CASE(dbo.sysschedules.freq_subday_interval)
					WHEN 0 THEN 'Once'
					ELSE CAST('Every ' 
							+ RIGHT(dbo.sysschedules.freq_subday_interval,2) 
							+ ' '
							+     CASE(dbo.sysschedules.freq_subday_type)
										WHEN 1 THEN 'Once'
										WHEN 4 THEN 'Minutes'
										WHEN 8 THEN 'Hours'
									END AS CHAR(16))
				END AS 'Subday Frequency'

FROM			dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN		dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN (SELECT		job_id
							, MAX(run_duration) AS run_duration

				FROM		dbo.sysjobhistory

				GROUP BY	job_id) Q1 ON dbo.sysjobs.job_id = Q1.job_id

WHERE			Next_run_time <> 0

ORDER BY		[Start Date]
				, [Start Time]
