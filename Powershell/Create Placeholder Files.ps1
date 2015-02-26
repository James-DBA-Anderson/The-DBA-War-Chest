param([string]$path)
IF ($path.Length -gt 0)
{
    $Placeholders = Get-ChildItem -Path $path | Where-object {$_.Name -like "Placeholder*"} | Sort-Object
    $Count = $Placeholders.Count + 1
    $FileName = $path + "Placeholder" + $Count
    $Drive = Get-Volume | Where-Object {$_.DriveLetter -eq $path.Substring(0,1)}
    $AvailableDisk = $Drive.SizeRemaining / 1024 / 1024 / 1024

    IF ($AvailableDisk -gt 10)
    {
        $AvailableDisk
        fsutil file createnew $FileName 1024000000   
    }
}