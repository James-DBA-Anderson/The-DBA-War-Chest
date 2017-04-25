
-- DBA War Chest 
-- SSRS Subscription Schedules
-- 2017-04-25

-- Show reports that are executed by which agent jobs

SELECT      b.name AS JobName
            , e.name
            , e.path
            , d.description
            , a.SubscriptionID
            , laststatus
            , eventtype
            , LastRunTime
            , date_created
            , date_modified

FROM ReportServer.dbo.ReportSchedule a 
LEFT JOIN msdb.dbo.sysjobs b ON CONVERT(SYSNAME, a.ScheduleID) = b.name
LEFT JOIN ReportServer.dbo.ReportSchedule c ON b.name = CONVERT(SYSNAME, c.ScheduleID)
LEFT JOIN ReportServer.dbo.Subscriptions d ON c.SubscriptionID = d.SubscriptionID
LEFT JOIN ReportServer.dbo.Catalog e ON d.report_oid = e.itemid