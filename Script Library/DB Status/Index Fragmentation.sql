
-- DBA War Chest 
-- Show Index Fragmentation Levels
-- 2015-03-24 

-- Show all indexes that have rfagmentation levels greater then the level set. 
-- Ignore indexes with small page counts as fragmentation will not have a noticable affect.

DECLARE @FragmentationPercentage INT = 30, @PageCount INT = 100

-- Set Params -----------------------------------------

SELECT	@FragmentationPercentage = 30 -- Show all indexes with an average fragmentation level >= 30%
		, @PageCount = 100 -- Show all indexes that contain more than 100 pages. 

--------------------------------------------------------

SELECT		OBJECT_NAME(ind.OBJECT_ID) AS TableName
			, ind.name AS IndexName
			, ins.page_count AS [PageCount]
			, ins.index_type_desc AS IndexType
			, ins.index_depth AS IndexDepth
			, ins.avg_fragmentation_in_percent

FROM		sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) ins
JOIN		sys.indexes ind ON ind.object_id = ins.object_id
							AND ind.index_id = ins.index_id

WHERE		ins.avg_fragmentation_in_percent >= @FragmentationPercentage
			AND ins.page_count >= @PageCount

ORDER BY	ins.avg_fragmentation_in_percent DESC

