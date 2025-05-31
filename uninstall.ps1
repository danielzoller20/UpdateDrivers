$PackageName = "UpdateDrivers"
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-uninstall.log" -Force
$ErrorActionPreference = 'Stop'

$SchTaskName = "UpdateDrivers"
$ProgramFolder = Join-Path $env:ProgramFiles -ChildPath "UpdateDrivers"
$LinkInStartMenu = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Treiber aktualisieren.lnk"

try {
    Unregister-ScheduledTask -TaskName $SchTaskName -Confirm:$false -ErrorAction Stop
    Write-Host "Scheduled Task $SchTaskName was removed"
}
catch {
    Write-Host "Removal of scheduled Task $SchTaskName threw errors"
}


try {
    Remove-Item -Path $ProgramFolder -Recurse -Force
    Write-Host "Folder $ProgramFolder was removed"
}
catch {
    Write-Host "Removing of Folder $ProgramFolder threw errors"
}


try {
    Remove-Item -Path $LinkInStartMenu -Force
    Write-Host "File $LinkInStartMenu was removed"
}
catch {
    Write-Host "Removing of File $LinkInStartMenu threw errors"
}

Stop-Transcript