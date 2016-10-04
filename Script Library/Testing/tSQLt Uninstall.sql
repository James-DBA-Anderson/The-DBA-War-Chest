
-- DBA War Chest 
-- Uninstall tSQLt
-- 2016-06-03

-- This is nice to do before committing code to source control as it keeps the project tidy.
-- Also keeps the deployment package tidy.
-- Test classes and tests will remain in the project which is good for source control of these objects.
-- A build server can re-install tSQLt, run tests and then uninstall for automated testing and CI.

EXEC [tSQLt].[Uninstall]