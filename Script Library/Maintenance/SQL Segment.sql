
-- test script

SELECT		SUBSTRING(s.text, p.stmt_start / 2, p.stmt_end / 2) AS SQL_Segment -- Divide by two if Unicode in use
			,*

FROM		sys.sysprocesses p
CROSS APPLY fn_get_sql(p.sql_handle) s 

WHERE		p.status NOT IN ('background','sleeping')