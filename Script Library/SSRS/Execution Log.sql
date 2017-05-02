
-- DBA War Chest 
-- SSRS Execution Log
-- 2017-05-02

-- List report executions

SELECT  c.Name,
		c.Path,
		u.UserName AS CreatedBy,
		u2.UserName AS ModifiedBy,
		CONVERT(XML, c.Parameter) AS Parameters,
		el.UserName AS RunTimeUser,
		el.[Parameters] AS RunTimeParams,
		el.TimeStart,
		el.TimeEnd,
		DATEDIFF(SECOND, el.TimeStart, el.TimeEnd) AS [Duration(s)],
		el.TimeDataRetrieval,
		el.TimeProcessing,
		el.TimeRendering,
		el.[RowCount] AS [RowCount]

FROM	ReportServer.dbo.Catalog c
JOIN	ReportServer.dbo.Users u ON c.CreatedByID = u.UserID
JOIN	ReportServer.dbo.Users u2 ON c.ModifiedByID = u2.UserID
JOIN	ReportServer.dbo.ExecutionLog el ON c.ItemID = el.ReportID

ORDER BY	el.TimeStart DESC

