
DBCC SQLPERF(LOGSPACE)

SELECT d.name, d.log_reuse_wait_desc, * 
FROM sys.databases d