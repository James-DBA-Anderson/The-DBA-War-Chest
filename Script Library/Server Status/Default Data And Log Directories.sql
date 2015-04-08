
-- DBA War Chest 
-- Default Data and Log Directories
-- 2015-03-31

-- Show the folders that databases use to store their data (.MDF, .NDF)
-- and log (.LDF) files by default. 


DECLARE @DefaultData NVARCHAR(512), @DefaultLog NVARCHAR(512), @MasterData NVARCHAR(512), @MasterLog NVARCHAR(512)

EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefaultData OUTPUT;

EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefaultLog OUTPUT;
 
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg0', @MasterData OUTPUT;

SELECT @MasterData=SUBSTRING(@MasterData, 3, 255);

SELECT @MasterData=SUBSTRING(@MasterData, 1, LEN(@MasterData) - CHARINDEX('\', REVERSE(@MasterData)));

EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg2', @MasterLog OUTPUT;

SELECT @MasterLog=SUBSTRING(@MasterLog, 3, 255);

SELECT @MasterLog=SUBSTRING(@MasterLog, 1, LEN(@MasterLog) - CHARINDEX('\', REVERSE(@MasterLog)));

SELECT	ISNULL(@DefaultData, @MasterData) DefaultData
		, ISNULL(@DefaultLog, @MasterLog) DefaultLog;