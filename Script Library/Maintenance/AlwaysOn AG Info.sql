
select primary_replica, primary_recovery_health_desc, synchronization_health_desc from sys.dm_hadr_availability_group_states
go
select * from sys.availability_groups
go
select * from sys.availability_groups_cluster
go

select replica_id, role_desc, connected_state_desc, synchronization_health_desc from sys.dm_hadr_availability_replica_states
go
select replica_server_name, replica_id, availability_mode_desc, endpoint_url from sys.availability_replicas
go
select replica_server_name, join_state_desc from sys.dm_hadr_availability_replica_cluster_states
go

select replica_id, role_desc, recovery_health_desc, synchronization_health_desc from sys.dm_hadr_availability_replica_states

select * from sys.availability_databases_cluster
go
select group_database_id, database_name, is_failover_ready  from sys.dm_hadr_database_replica_cluster_states
go
select database_id, synchronization_state_desc, synchronization_health_desc, last_hardened_lsn, redo_queue_size, log_send_queue_size from sys.dm_hadr_database_replica_states
go