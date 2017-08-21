
declare @cols table (Schemas SYSNAME, Tab SYSNAME, Col SYSNAME, Processed BIT DEFAULT 0) 
declare @results table (Schemas SYSNAME, Tab SYSNAME, Col SYSNAME)

insert @cols (Schemas, Tab, Col)
select s.name, OBJECT_NAME(c.object_id), c.name 
from sys.columns c
join sys.objects o on c.object_id = o.object_id
join sys.schemas s on s.schema_id = o.schema_id
where c.object_id > 100

DECLARE @SQL NVARCHAR(MAX), @Schemas SYSNAME, @Tab SYSNAME, @Col SYSNAME

WHILE EXISTS(SELECT * FROM @cols WHERE Processed = 0)
BEGIN
	SELECT TOP 1 @Schemas = Schemas, @Tab = Tab, @Col = Col FROM @cols WHERE Processed = 0

	SET @SQL = N'

	SELECT TOP 1 ''' + @Schemas + ''' AS Schemas, ''' + @Tab + ''' AS Tab, ''' + @Col + ''' AS Col
	FROM ' + QUOTENAME(@Schemas) + '.' + QUOTENAME(@Tab) + '
	WHERE ' + QUOTENAME(@Col) + ' LIKE ''%89%'' --devsys --queue_service 
	'

	BEGIN TRY
		INSERT @results
		EXEC sp_ExecuteSQL @SQL
	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE()
		PRINT 'Failed to execute the following SQL: ' + @SQL + @ErrMsg;
	END CATCH

	UPDATE @cols SET Processed = 1 WHERE Schemas = @Schemas AND Tab = @Tab AND Col = @Col
END

SELECT *
FROM @results