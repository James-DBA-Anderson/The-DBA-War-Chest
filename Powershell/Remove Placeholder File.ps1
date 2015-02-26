param([string]$path)
IF ($path.Length -gt 0)
{
    $Placeholders = Get-ChildItem -Path $path | Where-object {$_.Name -like "Placeholder*"} 
    $Count = $Placeholders.Count
    $FileName = $path + "Placeholder" + $Count

    IF ($Count -gt 0)
    {
        Remove-Item $FileName  
    }
}