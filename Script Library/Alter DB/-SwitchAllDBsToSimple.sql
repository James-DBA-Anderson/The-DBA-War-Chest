
-- DBA War Chest 
-- Switch All DBs to simple mode 
-- 2015-02-20 

-- TODO: Alter script to take recovery model as param and a list of DBs to alter the recovery model on.

Declare @SQL nvarchar(4000), @DBCounter int, @DBMaxCount int, @DBName nvarchar(100), @ErrMsg nvarchar(4000), @ErrSeverity int

Declare @DataBases table
(Id int identity(1,1),
DBName nvarchar(100))

Declare @Failures table
(Id int,
DBName nvarchar(100),
Error nvarchar(255))


Insert into @DataBases
SELECT	d.[name]
From	master.dbo.sysdatabases d --Non system DBs
Where	dbid > 6 and category = 0 
and		status <> 65568 -- restoring
order by 1

Set @DBCounter = 1
SELECT @DBMaxCount = COUNT(d.DBName) From @DataBases d

While @DBCounter <= @DBMaxCount
Begin
  Begin Try
	  Set @DBName = (Select d.DBName From @DataBases d Where Id = @DBCounter)
	  Set @SQL = 'ALTER DATABASE [' + @DBName + '] SET RECOVERY SIMPLE;'
	  EXEC SP_ExecuteSql @SQLToExecute = @SQL
  End Try
  Begin Catch
	SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()
    
    SELECT @DBCounter, @DBName, Cast(@ErrSeverity as varchar(6)) + ' ' + @ErrMsg
  End Catch  

  Set @DBCounter = @DBCounter + 1	
End
