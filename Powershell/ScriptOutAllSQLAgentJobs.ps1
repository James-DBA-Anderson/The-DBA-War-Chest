Import-Module "sqlps" -DisableNameChecking
Get-ChildItem -path SQLSERVER:SQL\bfxprod-clu-sql\default\JobServer\Jobs | %{$_.script()} | out-file -filepath "FileSystem::I:\Backups\Server Object Backups\BFXPROD-CLU-SQL--AgentJobs.sql"
