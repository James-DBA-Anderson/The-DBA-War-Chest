
-- DBA War Chest 
-- Add Linked Server 
-- 2015-03-24 

-- Add a SQL-Server linked server with current login

USE [master]
GO

DECLARE @NewLinkedServer nvarchar(50)

-- Set Linked Server Name ---------------------------

SET @NewLinkedServer = 'InstanceName'

-----------------------------------------------------

EXEC master.dbo.sp_addlinkedserver @server = @NewLinkedServer, @srvproduct=N'SQL Server'

GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'rpc', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'rpc out', @optvalue=N'True' --Allow DDL 
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'use remote collation', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=@NewLinkedServer, @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO
USE [master]
GO
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @NewLinkedServer, @locallogin = NULL , @useself = N'True'
GO
