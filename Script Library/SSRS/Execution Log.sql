
-- DBA War Chest 
-- SSRS Execution Log
-- 2017-05-02

-- List report executions


SELECT		c.Name,
			c.Path,
			u.UserName AS CreatedBy,
			u2.UserName AS ModifiedBy,
			CONVERT(XML, c.Parameter) AS Parameters,
			el.UserName AS RunTimeUser,
			CASE(el.RequestType)
				WHEN 0 THEN 'Interactive'
				WHEN 1 THEN 'Subscription'
				WHEN 2 THEN 'Refresh Cache'
				ELSE 'Unknown'
			END AS RequestType,
			el.Status,
			el.[Parameters] AS RunTimeParams,
			el.TimeStart,
			el.TimeEnd,
			DATEDIFF(SECOND, el.TimeStart, el.TimeEnd) AS [Duration(s)],
			el.TimeDataRetrieval,
			el.TimeProcessing,
			el.TimeRendering,
			el.[RowCount] AS [RowCount],
			CASE(el.Source)
				WHEN 1 THEN 'Live'
				WHEN 2 THEN 'Cache'
				WHEN 3 THEN 'Snapshot' 
				WHEN 4 THEN 'History'
				WHEN 5 THEN 'AdHoc'
				WHEN 6 THEN 'Session'
				WHEN 7 THEN 'Rdce'
				ELSE 'Unknown'
			END AS Source,			
			el.ByteCount
			
FROM		ReportServer.dbo.Catalog c
JOIN		ReportServer.dbo.Users u ON c.CreatedByID = u.UserID
LEFT JOIN	ReportServer.dbo.Users u2 ON c.ModifiedByID = u2.UserID
LEFT JOIN	ReportServer.dbo.ExecutionLog el ON c.ItemID = el.ReportID

ORDER BY	el.TimeStart DESC

