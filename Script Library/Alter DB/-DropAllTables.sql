
-- To do: Get all foreign keys from all tables and delete them first then drop all tables

--SELECT	name
--FROM		sys.objects
--WHERE		type = 'F'; 

Declare @Key nvarchar(200)
Declare @Schema nvarchar(50)
Declare @SQL nvarchar(max)

Declare @Tables table
(name nvarchar(200)
,object_id int)

Insert into @Tables
Select name, object_id
From Sys.tables 

Declare @Keys table
(name nvarchar(200))

Declare @Table nvarchar(200)
Declare @ObjectId int

While Exists(Select * From @Tables) 
Begin
	Select Top 1 @Table = name, @ObjectId = [object_id] From @Tables

	delete From @Keys
	insert into @Keys
	SELECT name 
	FROM sys.foreign_keys k
	Where object_id = @ObjectId

	Set @Schema = (Select OBJECT_SCHEMA_NAME(@ObjectId))

	While Exists(Select * From @Keys) 
	Begin
		Select Top 1 @Key = name From @Keys

		Set @SQL = 'ALTER TABLE [' + @Schema + '].[' + @Table + '] DROP CONSTRAINT [' + @Key + ']'

		EXEC SP_ExecuteSql @SQLToExecute = @SQL
		Print @Key + ' dropped!'

		Delete From @Keys Where name = @Key
	End

	Set @SQL = 'Drop Table [' + @Schema + '].[' + @Table + ']'

	EXEC SP_ExecuteSql @SQLToExecute = @SQL
	Print @Table + ' dropped!'

	Delete From @Tables Where name = @Table
End

