cls
# Set environment variables ########################

## Needs work on catching errors from SQLPackage.exe and treating them as terminating errors

$SQLPackagePath = "C:\program files\microsoft sql server\140\DAC\bin"
$DACPAC_Path = "C:\Projects\Communications\Source\Benefex.Communications.Db\bin\Debug\Communications.dacpac"

$DatabaseName = "Communications"
$TargetServer = "LocalHost"

$DriftReportPath = "C:\Temp\$DatabaseName Drift Report.xml"
$DeployReportPath = "C:\Temp\$DatabaseName Deploy Report.xml"
$DeployScriptPath = "C:\Temp\$DatabaseName Deployment Script.sql"
$DeployDiagnosticsPath = "C:\Temp\$DatabaseName Deployment Diagnostics.txt"

#####################################################

$Result = 0

# Add path for SQLPackage.exe
try {
    IF (-not ($env:Path).Contains($SQLPackagePath)) { 
        $env:path = $env:path + ";$SQLPackagePath;" 
    }
}
catch {
    $Result = 1
    Write-Error ("Failed adding SQLPackage to PATH: " + $errortext + $_)
    Exit 1
}

if ($Result -eq 0) {
    try {
        # Generate drift report

        Invoke-Command -ScriptBlock {
            try {
                SQLPackage /Action:DriftReport `
                /TargetServerName:$TargetServer `
                /TargetDatabaseName:$DatabaseName `
                /OverwriteFiles:True `
                /OutputPath:$DriftReportPath `
                /Quiet:True
            }
            cat
        } -ErrorAction Stop

        #[xml]$x = gc -Path $DriftReportPath;
        #$x.DeploymentReport.Operations.Operation |
        #% -Begin {$a=@();} -process {$name = $_.name; $_.Item | %  {$r = New-Object PSObject -Property @{Operation=$name; Value = $_.Value; Type = $_.Type} ; $a += $r;} }  -End {$a}
    }
    catch {
        $Result = 1
        Write-Error ("Failed to generate deployment report: " + $_)
        Exit 1
    }
} 

if ($Result -eq 0) {
    try {
        # Generate deployment report

        Invoke-Command -ScriptBlock {
            SQLPackage /Action:DeployReport `
            /SourceFile:$DACPAC_Path `
            /TargetServerName:$TargetServer `
            /TargetDatabaseName:$DatabaseName `
            /OverwriteFiles:True `
            /OutputPath:$DeployReportPath `
            /Properties:DropObjectsNotInSource=True `
            /Quiet:True
        } -ErrorAction Stop

        [xml]$x = gc -Path $DeployReportPath;
        $x.DeploymentReport.Operations.Operation |
        % -Begin {$a=@();} -process {$name = $_.name; $_.Item | %  {$r = New-Object PSObject -Property @{Operation=$name; Value = $_.Value; Type = $_.Type} ; $a += $r;} }  -End {$a}
    }
    catch {
        $Result = 1
        Write-Error ("Failed to generate deployment report: " + $_)
        Exit 1
    }
}

if ($Result -eq 0) {
    try {
        # Generate deployment script

        Invoke-Command -ScriptBlock {
            SQLPackage /Action:Script `
            /SourceFile:$DACPAC_Path `
            /TargetServerName:$TargetServer `
            /TargetDatabaseName:$DatabaseName `
            /OverwriteFiles:True `
            /OutputPath:$DeployScriptPath `
            /Properties:DropObjectsNotInSource=True `
            /Quiet:True
        } -ErrorAction Stop
    }
    catch {
        $Result = 1
        Write-Error ("Failed to generate deployment script: " + $_)
        Exit 1
    }
}

if ($Result -eq 0) {
    try {
        # Publish the DACPAC

        Invoke-Command -ScriptBlock {
            SQLPackage /Action:Publish `
            /SourceFile:$DACPAC_Path `
            /TargetServerName:$TargetServer `
            /TargetDatabaseName:$DatabaseName `
            /OverwriteFiles:True `
            /DiagnosticsFile:DeployDiagnosticsPath `
            /Properties:DropObjectsNotInSource=True `
            /Quiet:True
        } -ErrorAction Stop
    }
    catch {
        $Result = 1
        Write-Error ("Failed to publish DACPAC: " + $_)
        Exit 1
    }
}