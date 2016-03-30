

SELECT		tc.name TraceEventClass ,
			te.name TraceEvent,		
			tr.HostName,
			tr.ApplicationName,
			tr.LoginName,
			Duration, 
			tr.StartTime,
			tr.EndTime,
			(tr.IntegerData*8.)/1024 GrowthMB,
			tr.ServerName,
			tr.DatabaseName,
			tr.FileName, 
			left(path,patindex('%log_[0-9]%',path)-1)+'log.trc'

FROM		sys.traces t
CROSS APPLY sys.fn_trace_gettable(left(path,PATINDEX('%log_[0-9]%',path)-1)+'log.trc',default) tr
LEFT JOIN	sys.trace_events te ON tr.EventClass = te.trace_event_id
LEFT JOIN	sys.trace_categories tc ON te.category_id = tc.	category_id
LEFT JOIN	sys.trace_subclass_values tcv ON tr.EventClass = tcv.trace_event_id
											AND tr.EventSubClass = tcv.subclass_value

WHERE		t.is_default = 1
			AND tc.category_id = 2