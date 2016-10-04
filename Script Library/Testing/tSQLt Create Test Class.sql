
-- DBA War Chest 
-- Create tSQLt test class
-- 2016-06-03

-- The test classes are used to group tests for specific parts of a project.
-- tSQLt tests are assigned to a test class on creation.
-- All tests in a test class can be run at once.


EXEC tsqlt.NewTestClass @ClassName = 'MyNewTestClass';
GO
