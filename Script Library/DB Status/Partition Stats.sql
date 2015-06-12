
-- DBA War Chest 
-- Partition Stats 
-- 2015-05-28

-- Show the range value, number or rows and number of pages for each partition in each table.
-- Taken SQL Server 2008 Internals by Kalen Delaney, Paul S. Randal, Kimberly L. Tripp, and Conor Cunningham.

SELECT		OBJECT_NAME(i.object_id) AS OBJECT_NAME,
			p.partition_number,
			fg.NAME AS FILEGROUP_NAME,
			p.ROWS,
			au.total_pages,
			CASE boundary_value_on_right
				WHEN 1 THEN 'Less than'
				ELSE 'Less or equal than' 
			END AS 'Comparison',
			VALUE

FROM		sys.partitions p
JOIN		sys.indexes i ON p.object_id = i.object_id 
							AND p.index_id = i.index_id
JOIN		sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
JOIN		sys.partition_functions f ON f.function_id = ps.function_id
LEFT JOIN	sys.partition_range_values rv ON f.function_id = rv.function_id 
												AND p.partition_number = rv.boundary_id
JOIN		sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id 
												AND dds.destination_id = p.partition_number
JOIN		sys.filegroups fg ON dds.data_space_id = fg.data_space_id
JOIN		(
				SELECT container_id, SUM(total_pages) AS total_pages

				FROM sys.allocation_units

				GROUP BY container_id
			) AS au ON au.container_id = p.partition_id

WHERE		i.index_id < 2

ORDER BY	OBJECT_NAME
			,partition_number