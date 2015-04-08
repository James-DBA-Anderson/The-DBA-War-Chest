USE test_james
GO
CREATE ROLE [deny_log_backups]
GO
USE [test_james]
GO
CREATE USER [james] FOR LOGIN [james]
GO
ALTER USER [james] WITH DEFAULT_SCHEMA=[dbo]
GO
use test_james
GO
DENY BACKUP LOG TO [deny_log_backups]
GO
USE test_james
GO
EXEC sp_addrolemember N'deny_log_backups', N'james'
GO