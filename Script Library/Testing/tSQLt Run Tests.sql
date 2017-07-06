
-- DBA War Chest 
-- Run tSQLt tests
-- 2016-06-03

-- Create a tSQLt test class
/*
EXEC tSQLt.NewTestClass 'CreateTable';
*/

-- Run all, a subset or a specific tSQLt test

/* Run all tSQLt tests in the project
EXEC [tSQLt].[RunAll];
SELECT *  FROM tSQLt.TestResult;
EXEC [tSQLt].[DefaultResultFormatter]
*/


/* Run all tests for a specific test class
EXEC tSQLt.Run N'TestClass';
*/
SELECT @@TRANCOUNT
--ROLLBACK