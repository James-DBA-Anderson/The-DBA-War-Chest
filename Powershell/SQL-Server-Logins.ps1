$q = @"
SELECT name AS LoginName, 
DATEADD(DAY, CAST(LOGINPROPERTY(name, 'DaysUntilExpiration') AS int), GETDATE()) AS ExpirationDate,
create_date
FROM sys.server_principals
WHERE type = 'S'
"@

Add-PsSnapin *SQL*

$serverList = 'Instance1','Instance2'

foreach ($s in $serverList)
{
 Invoke-SqlCmd -ServerInstance $s -Database master -query $q
}