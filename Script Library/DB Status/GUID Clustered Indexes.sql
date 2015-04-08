
-- DBA War Chest 
-- Show All UNIQUEIDENTIFIER (GUID) Clustered Indexes
-- 2015-03-24 

-- Show all UNIQUEIDENTIFIER clustered indexes
-- This information is useful as these can be
-- problematic indexes when it comes to fragmentation

SELECT		object_name(a.object_id) AS [Table]
			, a.name
			, c.name

FROM		sys.indexes a
JOIN		(   
				SELECT		object_id
							, index_id

				FROM		sys.index_columns ic

				GROUP BY	object_id, index_id

				HAVING		max(index_column_id) = 1
			) b ON a.object_id = b.object_id 
				AND a.index_id = b.index_id
JOIN		sys.index_columns bb on b.object_id = bb.object_id and b.index_id = bb.index_id
JOIN		sys.columns  c on bb.object_id = c.object_id and bb.column_id = c.column_id
JOIN		sys.types d on c.user_type_id = d.user_type_id

WHERE		a.object_id > 1000	-- no system objects
			AND a.type = 1	-- clustered
			AND c.user_type_id = 36 --Unique Identifier



