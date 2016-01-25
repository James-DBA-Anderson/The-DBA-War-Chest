--Show Change Tracked Tables
SELECT	*
FROM	sys.tables t
JOIN	sys.change_tracking_tables ct ON t.object_id = ct.object_id

-- Enable Change Tracking on a table
/*
ALTER TABLE [Scema].[TableName]
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON)
*/

-- Disable Change Tracking on a table
/*
ALTER TABLE [Scema].[TableName]
DISABLE CHANGE_TRACKING;
*/