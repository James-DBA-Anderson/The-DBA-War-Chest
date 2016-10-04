param (
    [parameter(Mandatory=$true,Position=0)][string] $Source,
    [parameter(Mandatory=$true,Position=1)][string] $Destination,
    [parameter(Mandatory=$false,Position=2)][string] $Login,
    [parameter(Mandatory=$false,Position=3)][string] $DefaultDb = $null,
    [parameter(Mandatory=$false,Position=4)] $SQLLogin = $null,
    [parameter(Mandatory=$false,Position=5)] $SQLPass = $null,
    [switch] $OverwriteExisting = $False
)

# Load the SMO assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")

# Connect to the specified SQL Servers
$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $Source
$DestinationSQLServer = New-Object Microsoft.SqlServer.Management.Smo.Server $Destination
if ( $SQLLogin -ne $null -and $SQLPass -ne $null ) {
    # Use SQL Auth if it was specified
    $sqlServer.ConnectionContext.LoginSecure = $false
    $sqlServer.ConnectionContext.set_Login($SQLLogin)
    $sqlServer.ConnectionContext.set_Password($SQLPass)

    $DestinationSQLServer.ConnectionContext.LoginSecure = $false
    $DestinationSQLServer.ConnectionContext.set_Login($SQLLogin)
    $DestinationSQLServer.ConnectionContext.set_Password($SQLPass)
}

# Set up TSQL Statement
# If a Login was not specified, all SQL Logins
If ( [string]::IsNullOrEmpty($Login) ) {
    $query = "SELECT loginname, dbname, language, CONVERT(varchar(max),cast(password AS varbinary(256)),1) as passwd, dbname, CONVERT(varchar(max),sid,1) as sid "
    $query += "FROM syslogins WHERE isntuser = 0 and isntgroup = 0 and hasaccess = 1 and denylogin = 0 and status = 9 "
} Else {
    # Just the specified login
    $query = "SELECT loginname, dbname, language, CONVERT(varchar(max),cast(password AS varbinary(256)),1) as passwd, dbname, CONVERT(varchar(max),sid,1) as sid "
    $query += "FROM syslogins WHERE loginname = '${Login}'"
}

# Execute the query
$results = $sqlServer.Databases["master"].ExecuteWithResults($query)

# This array will store all the TSQL Queries that will be run against the Destination server
$inputs = New-Object System.Collections.ArrayList

ForEach ( $row in $results.Tables[0].Rows ) {
    # If it's ok to remove existing logins, add sp_droplogin
    if ( $OverwriteExisting ) {
        $input = "sp_droplogin @loginame = '" + $row.loginname + "'"
        $inputs += $input
    }
    # If a default DB was not specified at the command line...
    if ( [string]::IsNullOrEmpty($DefaultDb) ) {
        # Get a list of DBs on the destination server
        $DestinationDBList = @($DestinationSQLServer.Databases | select -expand Name)
        # if the list of DBs contains the same DB that was the default DB on the source server, set the default DB to that database
        if ($DestinationDBList -contains $row.dbname) {
            $defdb = $row.dbname
        } else {
            # Otherwise default to master
            $defdb = "master"
        }
    } else {
        # If it was specified, use the specified db for default DB
        $defdb = $DefaultDb
    }

    # Set up the TSQL for sp_addlogin
    # the SID, password, default db, and language are all preserved
    $input = "DECLARE @bpasswd varbinary(max)`n" + `
        "DECLARE @bsid varbinary(max)`n" + `
        "SELECT @bpasswd = CONVERT(varbinary(max),'" + $row.passwd  + "',1)`n" + `
        "SELECT @bsid = CONVERT(varbinary(max),'" + $row.sid+ "',1)`n" + `
        "EXEC sp_addlogin @loginame = '" + $row.loginname + `
        "', @defdb = '" + $defdb + "', @deflanguage = '" + $row.language + `
        "', @encryptopt = 'skip_encryption', @passwd = @bpasswd, @sid = @bsid;"
    $inputs += $input
}


ForEach ( $input in $inputs ) {
    # Loop through all the resulting T-SQL, output it to the screen, and then execute.
    Write-Host "------------"
    $input
    Write-Host "------------"
    $DestinationSQLServer.Databases["master"].ExecuteWithResults($input).Tables[0]
}