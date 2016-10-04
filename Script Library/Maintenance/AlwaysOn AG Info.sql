
-- DBA War Chest 
-- Gather information on AlwaysOn Availability Groups on the current instance
-- 2015-10-05


SELECT	primary_replica, primary_recovery_health_desc, synchronization_health_desc 
FROM	sys.dm_hadr_availability_group_states
GO;

SELECT	* 
FROM	sys.availability_groups
GO;

SELECT	* 
FROM	sys.availability_groups_cluster
GO;

SELECT	replica_id, role_desc, connected_state_desc, synchronization_health_desc 
FROM	sys.dm_hadr_availability_replica_states
GO;

SELECT	replica_server_name, replica_id, availability_mode_desc, endpoint_url 
FROM	sys.availability_replicas
GO;

SELECT	replica_server_name, join_state_desc 
FROM	sys.dm_hadr_availability_replica_cluster_states
GO;

SELECT	replica_id, role_desc, recovery_health_desc, synchronization_health_desc 
FROM	sys.dm_hadr_availability_replica_states
GO;

SELECT	* 
FROM	sys.availability_databases_cluster
GO;

SELECT	group_database_id, database_name, is_failover_ready  
FROM	sys.dm_hadr_database_replica_cluster_states
GO;

SELECT	database_id, synchronization_state_desc, synchronization_health_desc, last_hardened_lsn, redo_queue_size, log_send_queue_size 
FROM	sys.dm_hadr_database_replica_states
GO;

-- Connections
/*
SELECT	es.login_name
		,es.program_name
		,ec.client_net_address
		,ec.client_tcp_port
		,agl.dns_name
		,aglip.ip_address
		,agl.port
FROM sys.availability_group_listeners agl
INNER JOIN sys.availability_group_listener_ip_addresses aglip ON agl.listener_id = aglip.listener_id
INNER JOIN sys.dm_exec_connections ec ON ec.local_net_address = aglip.ip_address
INNER JOIN sys.dm_exec_sessions es ON ec.session_id = es.session_id
UNION ALL
SELECT	es.login_name
		,es.program_name
		,ec.client_net_address
		,ec.client_tcp_port
		,@@SERVERNAME AS [dns_name]
		,sr.value_data AS [ip_Address]
		,ec.local_tcp_port AS [port]
FROM sys.dm_server_registry sr
INNER JOIN sys.dm_exec_connections ec ON sr.value_name = 'IpAddress' AND ec.local_net_address = sr.value_data 
INNER JOIN sys.dm_exec_sessions es ON ec.session_id = es.session_id
*/