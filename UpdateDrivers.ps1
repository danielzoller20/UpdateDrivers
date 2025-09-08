###########################################################################
# parameter to update BIOS
###########################################################################

param(
    [Parameter(Mandatory=$false)]
    [switch]$BIOS=$false,
    [Parameter(Mandatory=$false)]
    [switch]$reinstall=$false
)


###########################################################################
# functions
###########################################################################

function Remove-UnwantedUpdates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
        $AllUpdates
    )

    begin {
        $collectedUpdates = @()
    }

    process {
        $collectedUpdates += $AllUpdates
    }

    end {
        # 1) Filter by ID regex
        $IDRegexFilteredUpdates = $collectedUpdates |
            Where-Object {
                $UpdateID = $_.Id
                -not ($UnwantedUpdatesByIDRegex | Where-Object { $UpdateID -match $_ })
            }

        # 2) Filter by explicit ID list
        $IDFilteredUpdates = $IDRegexFilteredUpdates |
            Where-Object { $_.Id -notin $UnwantedUpdatesByID }

        # 3) Device-specific EXCLUSION rules:
        #    If the rule returns $true for an update, that update is EXCLUDED (not applied).
        if ($DeviceModel -and $UnwantedUpdatesByDevice -and $UnwantedUpdatesByDevice.ContainsKey($DeviceModel)) {
            Write-Host "Device is $DeviceModel, applying device-specific EXCLUSION rules (matching updates will NOT be applied)."

            # Accept either scriptblock or string; compile string if needed
            $deviceRule = $UnwantedUpdatesByDevice[$DeviceModel]
            if ($deviceRule -is [string]) {
                $deviceRule = [ScriptBlock]::Create($deviceRule)
            }

            # IMPORTANT: invoke the rule and invert it so matches are excluded
            $FinalFilteredUpdates = $IDFilteredUpdates | Where-Object { -not (& $deviceRule) }
        }
        else {
            Write-Host "Device is $DeviceModel, no device-specific exclusions."
            $FinalFilteredUpdates = $IDFilteredUpdates
        }

        # Informational: which were excluded (don’t return them)
        $FinalIds = $FinalFilteredUpdates.Id
        $UnwantedUpdates = $collectedUpdates | Where-Object { $_.Id -notin $FinalIds }
        if ($UnwantedUpdates) {
            Write-Host "Excluded updates:"
            $UnwantedUpdates | ForEach-Object { Write-Host " - $($_.Id) $($_.Name)" }
        }

        if ($updateDefinitionsUrl) {
            Write-Host "see $updateDefinitionsUrl for excluded updates"
        }

        # Return allowed updates
        $FinalFilteredUpdates
    }
}


###########################################################################
# variables
###########################################################################

$RootDirectory = Join-Path $env:windir -ChildPath "Logs\UpdateDrivers"
$DateTimeFormat = "yyyy-MM-dd_HH-mm-ss"
$StartTime = Get-Date -Format $DateTimeFormat
$LogName = $StartTime+"_"+$env:COMPUTERNAME+".txt"
$LogFilePath = Join-Path -Path $RootDirectory -ChildPath $LogName
Start-Transcript -Path $LogFilePath
Write-Host (Get-Date -Format $DateTimeFormat)-" script started"


###########################################################################
# unwanted updateds
###########################################################################


$updateDefinitionsUrl = "https://raw.githubusercontent.com/danielzoller20/UpdateDrivers/refs/heads/main/UnwantedUpdates.ps1"

Invoke-Expression (Invoke-RestMethod -Uri $updateDefinitionsUrl) -Verbose



###########################################################################
# install NuGet
###########################################################################

$InstalledNuGuet = Get-PackageProvider | Where-Object {$_.Name -eq "NuGet"}
$RequiredNuGetVersion = "2.8.5.201"

# PackageProvider NuGet not found
if ($null -eq $InstalledNuGuet) {
    Write-Host "NuGet needs to be installed"
    try {
        Install-PackageProvider -Name NuGet -RequiredVersion $RequiredNuGetVersion -Force -ErrorAction Stop
        Write-Host "NuGet installation sucessful"
    }
    catch {
        Write-Host "NuGet could not be installed, script will exit!"
        exit(1)
    }
}

# something found for NuGet PackagePrivder
else {
    # try to get NuGet Version
    try {
        $NuGetVersion = ((Get-PackageProvider -name NuGet -Force -ErrorAction Stop).Version)
        Write-Host "found or installed NuGet version $NuGetVersion" -ForegroundColor Green
        }
    catch {
        Write-Host "Something went wrong, will install NuGet $RequiredNuGetVersion or above"
    }
    finally {
        # check for required NuGuet version
        if ($NuGetVersion -ge $RequiredNuGetVersion) {
            Write-Host "current NuGet Version is greater or equal required version $RequiredNuGetVersion" -ForegroundColor Green
        }
        else {
            Write-Host "NuGet needs to be updated to $RequiredNuGetVersion or above"
            Install-PackageProvider -Name NuGet -RequiredVersion $RequiredNuGetVersion -Force
            Write-Host "NuGet installation sucessful"
        }
    }
}

# get device manufacturer
$ComputerInfo = Get-ComputerInfo
$DeviceManufacturer = $ComputerInfo.CsManufacturer
$DeviceModel = $ComputerInfo.CsModel

# if device is from HP
if ($DeviceManufacturer -eq "HP") {
    Write-Host "This device seems to be manufactured by HP"
    $UpdatePSModule = "HPDrivers"
    # $UpdatePrompt is executed to update all the drivers
    if ($reinstall) {
        Write-Host "Switch-Parameter to reinstall drivers was passed"
        $UpdatePrompt = {Get-HPDrivers -NoPrompt -DeleteInstallationFiles -BIOS -Overwrite |  Remove-UnwantedUpdates}
    }
    else {
        if ($BIOS -eq $true) {
            Write-Host "Switch-Parameter to update BIOS was passed"
            $UpdatePrompt = {Get-HPDrivers -NoPrompt -DeleteInstallationFiles -BIOS |  Remove-UnwantedUpdates}
        }
        else {
            Write-Host "Switch-Parameter to update BIOS was not passed"
            $UpdatePrompt = {Get-HPDrivers -NoPrompt -DeleteInstallationFiles|  Remove-UnwantedUpdates}
        }
    }

    
}

# if device is from Lenovo
elseif ($DeviceManufacturer -eq "Lenovo") {
    Write-Host "This device seems to be manufactured by Lenovo"
    $UpdatePSModule = "LSUClient"
    $UpdateSavePath = Join-Path -Path $env:windir -ChildPath "Temp\LenovoDrivers"
    # $UpdatePrompt is executed to update all the drivers
    $UpdatePrompt = {
        if ($reinstall) {
            Write-Host "Switch-Parameter to reinstall drivers was passed"
            $Updates = Get-LSUpdate -All | Where-Object { $_.Installer.Unattended } | Remove-UnwantedUpdates
        }
        else {
            if ($BIOS -eq $true) {
            Write-Host "Switch-Parameter to update BIOS was passed"
            $Updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended } | Remove-UnwantedUpdates
            }
            else {
                Write-Host "Switch-Parameter to update BIOS was not passed"
                $Updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended } | Where-Object {$_.Type -ne "BIOS"} |  Remove-UnwantedUpdates
            }
        }

        
        if ($null -eq $Updates) {
            Write-Host "No updates pending, script will exit"
        }
        else {
            Write-Host "Drivers will be updated..." -ForegroundColor Yellow
            Write-Host "found updates: $Updates"
            New-Item -ItemType Directory -Path $UpdateSavePath -Force
            $Updates | Save-LSUpdate -Path $UpdateSavePath
            $Updates | Install-LSUpdate
            try {
                Remove-Item -Path $UpdateSavePath -Force -Recurse -ErrorAction Stop
                Write-Host "cleared temporary folder for driver-downloads" -ForegroundColor Green
            }
            catch {
                Write-Host "temporary folder for driver-downloads could not be cleared" -ForegroundColor Red
            }
        }
    }
}

else {
    Write-Host "Device Manufacturer $DeviceManufacturer currently not supported"
    Exit(1)
}

###########################################################################
# install module for updating drivers
###########################################################################

Write-Host "checking for module $UpdatePSModule"

# get version of module
$ModuleVersion = (Get-Module -ListAvailable -Name $UpdatePSModule -ErrorAction Stop).Version

# install module if version is null
if ($null -eq $ModuleVersion) {
    Write-Host "module not found, will be installed"
    Install-Module -Name $UpdatePSModule -Force
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
    Import-Module -Name $UpdatePSModule -Force
    Write-Host "module installation sucessful"
    
}
else {
    Write-Host "found module $UpdatePSModule version $ModuleVersion" -ForegroundColor Green
}



###########################################################################
# remove unwanted folders
###########################################################################

$ExplicitRemoveFolders = @(
    "DRIVER",
    "Drivers"
)

$RegexRemoveFolders = '^Program\d+$'

$AllFoldersInC = Get-ChildItem -Path "C:\" -Directory

foreach ($FolderInC in $AllFoldersInC) {
    $FolderName = $FolderInC.Name

    if ($FolderName -match $RegexRemoveFolders -or $ExplicitRemoveFolders -contains $FolderName) {
        Write-Host "$FolderName will be removed from C:\" -ForegroundColor Yellow
        Remove-Item -Path $FolderInC.FullName -Recurse -Force
    }
    else {
        Write-Host "$FolderName will stay on C:\"
    }
}


###########################################################################
# update drivers
###########################################################################

& $UpdatePrompt

Write-Host (Get-Date -Format $DateTimeFormat)-" script terminated"
Stop-Transcript