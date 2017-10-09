@ECHO OFF
CLS
TITLE Deploy the DACPAC
SETLOCAL EnableExtensions EnableDelayedExpansion

:: Set environment variables ########################

SET SQLPackagePath="C:\program files (x86)\microsoft sql server\140\DAC\bin"
SET DACPAC_Path="C:\Temp\dbareports.dacpac"
 
SET DatabaseName=dbareports
SET TargetServer=FH-Test-SQL\SQLQA

SET "OutputPath=C:\Temp\"
IF NOT %OutputPath:~-1% == \ SET OutputPath=%OutputPath%\

SET "DriftReportPath=%OutputPath%%DatabaseName% Drift Report.xml"
SET "DeployReportPath=%OutputPath%%DatabaseName% Deploy Report.xml"
SET "DeployScriptPath=%OutputPath%%DatabaseName% Deployment Script.sql"
SET "DeployDiagnosticsPath=%OutputPath%%DatabaseName% Deployment Diagnostics.txt"

:: ##################################################

CD %SQLPackagePath%

:: Only run drift report if the database exists
FOR /F %%i IN ('SQLCMD -S %TargetServer% -h-1 -Q "SET NOCOUNT ON; SELECT name from sys.databases WHERE name='%DatabaseName%'"') DO (
	SQLPackage.exe /Action:DriftReport /TargetServerName:"%TargetServer%" /TargetDatabaseName:"%DatabaseName%" /OverwriteFiles:True /OutputPath:"%DriftReportPath%" /Quiet:True
	IF %ERRORLEVEL% NEQ 0 GOTO DriftReportError
)

SQLPackage.exe /Action:DeployReport /SourceFile:"%DACPAC_Path%" /TargetServerName:"%TargetServer%" /TargetDatabaseName:"%DatabaseName%" /OverwriteFiles:True /OutputPath:"%DeployReportPath%" /Properties:DropObjectsNotInSource=True /Quiet:True 
IF %ERRORLEVEL% NEQ 0 GOTO DeployReportError

SQLPackage.exe /Action:Script /SourceFile:"%DACPAC_Path%" /TargetServerName:"%TargetServer%" /TargetDatabaseName:"%DatabaseName%" /OverwriteFiles:True /OutputPath:"%DeployScriptPath%" /Properties:DropObjectsNotInSource=True /Quiet:True 
IF %ERRORLEVEL% NEQ 0 GOTO ScripttError

SQLPackage.exe /Action:Publish /SourceFile:"%DACPAC_Path%" /TargetServerName:"%TargetServer%" /TargetDatabaseName:"%DatabaseName%" /OverwriteFiles:True /DiagnosticsFile:"%DeployDiagnosticsPath%" /Properties:DropObjectsNotInSource=True /Quiet:True
IF %ERRORLEVEL% NEQ 0 GOTO PublishError

GOTO End

:DriftReportError
ECHO Failed generating drift report.
ECHO Canceling deployment.
EXIT /b 1

:DeployReportError
ECHO Failed generating deployment report.
ECHO Canceling deployment.
EXIT /b 1

:ScripttError
ECHO Failed generating deployment script.
ECHO Canceling deployment.
EXIT /b 1

:PublishError
ECHO Failed publishing database. 
ECHO Canceling deployment.
EXIT /b 1

:End
ECHO Deployment complete.