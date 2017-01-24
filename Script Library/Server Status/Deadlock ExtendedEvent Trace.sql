/***********************************************************************
Copyright 2016, Kendra Little - LittleKendra.com
MIT License, http://www.opensource.org/licenses/mit-license.php
***********************************************************************/

/***********************************************************************
COLLECT DEADLOCK GRAPHS WITH EXTENDED EVENTS

This script contains TSQL to:
	* Create an Extended Events Trace collecting sqlserver.xml_deadlock_report
	* Start the trace
	* Code to stop and delete the trace is commented out

Notes:
	This works with SQL Server 2012 and higher
	Change the filename to a relevant location on the server itself 
	Tweak options in the WITH clause to your preference
	Note that there is no automatic stop for this! If you want that, use a 
		Server Side SQL Trace instead.

	THIS CREATES AND STARTS AN EXTENDED EVENTS TRACE
***********************************************************************/



/* Create the Extended Events trace */
CREATE EVENT SESSION [Deadlock Report] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report
ADD TARGET package0.event_file
	(SET filename=
		N'S:\XEvents\deadlock-report.xel', max_file_size=(1024),max_rollover_files=(4))
		/* File size is in MB */
WITH (
	MAX_MEMORY=4096 KB,
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=30 SECONDS /* 0 = unlimited */,
	MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE=NONE,
	TRACK_CAUSALITY=OFF,
	STARTUP_STATE=ON)
GO


/* Start the Extended Events trace */
ALTER EVENT SESSION [Deadlock Report] 
	ON SERVER  
	STATE = START;  
GO


/***********************************************************************
Test a deadlock with the code here:
	https://www.littlekendra.com/2016/09/13/deadlock-code-for-the-wideworldimporters-sample-database/
***********************************************************************/



/* Stop the Extended Events trace when you want with a command like this */

--ALTER EVENT SESSION [Deadlock Report]  
--	ON SERVER  
--	STATE = STOP;  
--GO

/* Drop the trace when you're done with a command like this */

--DROP EVENT SESSION [Deadlock Report] ON SERVER;
--GO