
-- DBA War Chest 
-- Run tSQLt tests
-- 2016-06-03

-- Create a tSQLt test class
/*
EXEC tSQLt.NewTestClass 'CreateCSITable';
*/

-- Run all, a subset or a specific tSQLt test

/* Run all tSQLt tests in the project
EXEC [tSQLt].[RunAll];
*/


/* Run all tests for a specific test class
EXEC tSQLt.Run N'CreateCSITable';
*/
SELECT @@TRANCOUNT
--ROLLBACK