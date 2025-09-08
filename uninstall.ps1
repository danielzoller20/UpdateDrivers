$PackageName = "UpdateDrivers"
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-uninstall.log" -Force
$ErrorActionPreference = 'Stop'

$SchTaskName = "UpdateDrivers"
$ProgramFolder = Join-Path $env:ProgramFiles -ChildPath "UpdateDrivers"
$LinksInStartMenu = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Treiber aktualisieren"

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
    Remove-Item -Path $LinksInStartMenu -Recurse -Force
    Write-Host "Folder $LinksInStartMenu was removed"
}
catch {
    Write-Host "Removing of Folder $LinksInStartMenu threw errors"
}


Stop-Transcript