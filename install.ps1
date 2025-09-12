###########################################################################
# parameters and variables
###########################################################################

[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)]
    [switch]$EnableAutoUpdate=$false
)

$PackageName = "UpdateDrivers"
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-install.log" -Force

Write-Verbose -Message "Switch to enable Auto-Update is set to: $EnableAutoUpdate"

$ErrorActionPreference = 'Stop'
Write-Verbose -Message "ErrorActionPreference set to $ErrorActionPreference"

$ScriptFolder = Join-Path 'C:\Program Files' -ChildPath "UpdateDrivers"
$DateTimeFormat = "yyyy-MM-dd_HH-mm-ss"
Write-Host (Get-Date -Format $DateTimeFormat)-" script started"

###########################################################################
# folders and files
###########################################################################

# make folder in Program Files
if (!(Test-Path $ScriptFolder)) {
    try {
        Write-Host (Get-Date -Format $DateTimeFormat)-" Scriptfolder needs to be created"
        New-Item -Path $ScriptFolder -ItemType Directory
    }
    catch {
        Write-Host (Get-Date -Format $DateTimeFormat)-" could not create folder, script will exit" -ForegroundColor Red
        exit(1618)
    }
}

else {
    Write-Host (Get-Date -Format $DateTimeFormat)-" Scriptfolder already seems to exist"
}


# copy update-script to folder
$UpdateScriptName = "UpdateDrivers.ps1"
$UpdateScriptOldPath = Join-Path -Path $PSScriptRoot -ChildPath $UpdateScriptName
$UpdateScriptNewPath = Join-Path -Path $ScriptFolder -ChildPath $UpdateScriptName
Copy-Item -Path $UpdateScriptOldPath -Destination $UpdateScriptNewPath -Force



# make entry in common start menu
$StartmenuDir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"
try {
    $UpdateLinks = "Treiber aktualisieren"
    $UpdateLinksPath = Join-Path -Path $PSScriptRoot -ChildPath $UpdateLinks
    Copy-Item -Path $UpdateLinksPath -Destination $StartmenuDir -Recurse -Force
}
catch {
    Write-Output "no shortcuts added to startmenu"
    exit(1618)
}


###########################################################################################
# Register a scheduled task to run every 2 weeks
###########################################################################################

if ($EnableAutoUpdate) {
    $SchTaskName = "UpdateDrivers"
    $SchTaskDescription = "Update drivers"
    $Settings= New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 60) -DontStopOnIdleEnd -RunOnlyIfNetworkAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 2 -DaysOfWeek Wednesday -At 1pm
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$UpdateScriptNewPath`""
    try {
        Register-ScheduledTask -TaskName $SchTaskName -Trigger $Trigger -Action $Action -user "System" -Settings $Settings -Description $SchTaskDescription -Force
        Write-Host "registered scheduled task $SchTaskName"
    }
    catch {
        Write-Host "could not register scheduled task $SchTaskName"
        exit(1618)
    }
}


Stop-Transcript