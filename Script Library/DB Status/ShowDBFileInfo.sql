
-- DBA War Chest 
-- Show Database File Info
-- 2015-03-24 

-- Display all data files for all databases with size and growth info


SELECT  d.name AS [Database],
		Sf.dbid,  
		SF.fileid,
		SF.name [LogicalFileName],   
		CASE SF.status & 0x100000  
			WHEN 1048576 THEN 'Percentage' 
			WHEN 0 THEN 'MB' 
		END AS FileGrowthOption,
		Growth AS GrowthUnit,
		Round(((Cast(Size as float)*8)/1024)/1024,2) [SizeGB], -- Convert 8k pages to GB
		Maxsize,		
		filename AS PhysicalFileName

FROM	Master.SYS.SYSALTFILES SF
Join	Master.SYS.Databases d on sf.dbid = d.database_id

Order by d.name



