
SELECT		ps.name AS PartitionScheme
			, fg.name AS [FileGroup]
			, prv.*			
			, LAG(prv.Value) OVER (PARTITION BY ps.name ORDER BY ps.name, boundary_id) AS PreviousBoundaryValue

FROM		sys.partition_schemes ps
INNER JOIN	sys.destination_data_spaces dds
			ON dds.partition_scheme_id = ps.data_space_id
INNER JOIN	sys.filegroups fg
			ON dds.data_space_id = fg.data_space_id
INNER JOIN	sys.partition_functions f
			ON f.function_id = ps.function_id
INNER JOIN	sys.partition_range_values prv
			ON f.function_id = prv.function_id
			AND dds.destination_id = prv.boundary_id


