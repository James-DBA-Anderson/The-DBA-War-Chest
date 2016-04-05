
-- DBA War Chest 
-- SQL Agent Job History
-- 2016-04-01

-- Script was written by Steve Stedman
-- http://stevestedman.com/2016/03/tsql-script-display-agent-job-history/

;WITH jobListCTE as
(
SELECT j.name as job_name,
msdb.dbo.agent_datetime(run_date, run_time) AS run_datetime,
RIGHT('000000' + CONVERT(varchar(6), run_duration), 6) AS run_duration,
message
FROM msdb.dbo.sysjobhistory h
INNER JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.step_name = '(Job outcome)'
)
SELECT job_name as [JobStep],
run_datetime as [StartDateTime],
SUBSTRING(run_duration, 1, 2) + ':' +
SUBSTRING(run_duration, 3, 2) + ':' +
SUBSTRING(run_duration, 5, 2) as [Duration],
message
FROM jobListCTE
ORDER BY run_datetime DESC, job_name;