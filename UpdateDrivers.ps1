###########################################################################
# parameter to update BIOS
###########################################################################

param(
    [Parameter(Mandatory=$false)]
    [switch]$BIOS=$false
)


###########################################################################
# functions
###########################################################################

function  Remove-UnwantedUpdates {
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true
        )]
        $AllUpdates

    )

    begin {
        $collectedUpdates = @()
    }

    process {
        $collectedUpdates += $AllUpdates
    }

    end {
        $IDRegexFilteredUpdates = $collectedUpdates | Where-Object {
            $UpdateID = $_.Id
            -not ($UnwantedUpdatesByIDRegex | Where-Object { $UpdateID -match $_ })
        }

            $IDFilteredUpdates = $IDRegexFilteredUpdates | Where-Object {
            $_.Id -notin $UnwantedUpdatesByID
        }

        
        if ($DeviceModel -and $UnwantedUpdatesByDevice.ContainsKey($DeviceModel)) {
            Write-Host "Device is $DeviceModel, some Updates are not applied"
            $deviceFilterScript = [ScriptBlock]::Create($UnwantedUpdatesByDevice[$DeviceModel])
            $FinalFilteredUpdates = $IDFilteredUpdates | Where-Object {
            -not ($deviceFilterScript.Invoke($_))
            }

        }
        else {
            Write-Host "Device is $DeviceModel, all Updates are applied"
             $FinalFilteredUpdates = $IDFilteredUpdates
        }

        $FinalFilteredUpdates
    }

}

###########################################################################
# variables
###########################################################################

$RootDirectory = Join-Path $env:ProgramFiles -ChildPath "UpdateDrivers"
$DateTimeFormat = "yyyy-MM-dd_HH-mm-ss"
$StartTime = Get-Date -Format $DateTimeFormat
$LogName = $StartTime+"_"+$env:COMPUTERNAME+".txt"
$LogFilePath = Join-Path -Path $RootDirectory -ChildPath $LogName
Start-Transcript -Path $LogFilePath
Write-Host (Get-Date -Format $DateTimeFormat)-" script started"


###########################################################################
# unwanted updateds
###########################################################################

# need to be identified by id, e.g. sp142036 (HP) or kbwl15rf (Lenovo)
$UnwantedUpdatesByID = @(
    "UnwantedSample", # Sample
    "kbwl15rf", # WiFi-Driver for Lenovo 13w Yoga Gen2
    "kbwl16rf" # another WiFi-Driver for Lenovo 13w Yoga Gen2
)

$UnwantedUpdatesByIDRegex = @(
    "(?i)^kbwl\d{2}rf$",
    "(?i)^kbwl\d{1}rf$"
)

$UnwantedUpdatesByDevice = @{
    "82YS" = {$_.Category -eq "Networking Wireless LAN"}
    "HP ProBook x360 435 G8 Notebook PC" = {$_.Name -like "Realtek RTL8*"}
}


###########################################################################
# install NuGet
###########################################################################

$InstalledNuGuet = Get-PackageProvider | Where-Object {$_.Name -eq "NuGet"}
$RequiredNuGetVersion = "2.8.5.201"

# PackageProvider NuGet not found
if ($null -eq $InstalledNuGuet) {
    Write-Host (Get-Date -Format $DateTimeFormat)-" NuGet needs to be installed"
    try {
        Install-PackageProvider -Name NuGet -RequiredVersion $RequiredNuGetVersion -Force -ErrorAction Stop
        Write-Host (Get-Date -Format $DateTimeFormat)-" NuGet installation sucessful"
    }
    catch {
        Write-Host (Get-Date -Format $DateTimeFormat)-" NuGet could not be installed, script will exit!"
        exit(1)
    }
}

# something found for NuGet PackagePrivder
else {
    # try to get NuGet Version
    try {
        $NuGetVersion = ((Get-PackageProvider -name NuGet -Force -ErrorAction Stop).Version)
        Write-Host (Get-Date -Format $DateTimeFormat)-" found or installed NuGet version $NuGetVersion" -ForegroundColor Green
        }
    catch {
        Write-Host (Get-Date -Format $DateTimeFormat)-" Something went wrong, will install NuGet $RequiredNuGetVersion or above"
    }
    finally {
        # check for required NuGuet version
        if ($NuGetVersion -ge $RequiredNuGetVersion) {
            Write-Host (Get-Date -Format $DateTimeFormat)-" current NuGet Version is greater or equal required version $RequiredNuGetVersion" -ForegroundColor Green
        }
        else {
            Write-Host (Get-Date -Format $DateTimeFormat)-" NuGet needs to be updated to $RequiredNuGetVersion or above"
            Install-PackageProvider -Name NuGet -RequiredVersion $RequiredNuGetVersion -Force
            Write-Host (Get-Date -Format $DateTimeFormat)-" NuGet installation sucessful"
        }
    }
}

# get device manufacturer
$ComputerInfo = Get-ComputerInfo
$DeviceManufacturer = $ComputerInfo.CsManufacturer
$DeviceModel = $ComputerInfo.CsModel

# if device is from HP
if ($DeviceManufacturer -eq "HP") {
    Write-Host (Get-Date -Format $DateTimeFormat)-" This device seems to be manufactured by HP"
    $UpdatePSModule = "HPDrivers"
    # $UpdatePrompt is executed to update all the drivers
    
    if ($BIOS -eq $true) {
        Write-Host (Get-Date -Format $DateTimeFormat)-" Switch-Parameter to update BIOS was passed"
        $UpdatePrompt = {Get-HPDrivers -NoPrompt -DeleteInstallationFiles -BIOS |  Remove-UnwantedUpdates}
    }
    else {
        Write-Host (Get-Date -Format $DateTimeFormat)-" Switch-Parameter to update BIOS was not passed"
        $UpdatePrompt = {Get-HPDrivers -NoPrompt -DeleteInstallationFiles|  Remove-UnwantedUpdates}
    }
    
}

# if device is from Lenovo
elseif ($DeviceManufacturer -eq "Lenovo") {
    Write-Host (Get-Date -Format $DateTimeFormat)-" This device seems to be manufactured by Lenovo"
    $UpdatePSModule = "LSUClient"
    $UpdateSavePath = Join-Path -Path $RootDirectory -ChildPath "Drivers"
    # $UpdatePrompt is executed to update all the drivers
    $UpdatePrompt = {
        if ($BIOS -eq $true) {
            Write-Host (Get-Date -Format $DateTimeFormat)-" Switch-Parameter to update BIOS was passed"
            $Updates = Get-LSUpdate |  Remove-UnwantedUpdates
        }
        else {
            Write-Host (Get-Date -Format $DateTimeFormat)-" Switch-Parameter to update BIOS was not passed"
            $Updates = Get-LSUpdate | Where-Object {$_.Type -ne "BIOS"} |  Remove-UnwantedUpdates
        }
        
        if ($null -eq $Updates) {
            Write-Host (Get-Date -Format $DateTimeFormat)-" No updates pending, script will exit"
        }
        else {
            Write-Host (Get-Date -Format $DateTimeFormat)-" Drivers will be updated..." -ForegroundColor Yellow
            Write-Host (Get-Date -Format $DateTimeFormat)-" found updates: $Updates"
            New-Item -ItemType Directory -Path $UpdateSavePath -Force
            $Updates | Save-LSUpdate -Path $UpdateSavePath
            $Updates | Install-LSUpdate
            try {
                Remove-Item -Path $UpdateSavePath -Force -Recurse -ErrorAction Stop
                Write-Host (Get-Date -Format $DateTimeFormat)-" cleared temporary folder for driver-downloads" -ForegroundColor Green
            }
            catch {
                Write-Host (Get-Date -Format $DateTimeFormat)-" temporary folder for driver-downloads could not be cleared" -ForegroundColor Red
            }
        }
    }
}

else {
    Write-Host (Get-Date -Format $DateTimeFormat)-" Device Manufacturer $DeviceManufacturer currently not supported"
    Exit(1)
}

###########################################################################
# install module for updating drivers
###########################################################################

Write-Host (Get-Date -Format $DateTimeFormat)-" checking for module $UpdatePSModule"

# get version of module
$ModuleVersion = (Get-Module -ListAvailable -Name $UpdatePSModule -ErrorAction Stop).Version

# install module if version is null
if ($null -eq $ModuleVersion) {
    Write-Host (Get-Date -Format $DateTimeFormat)-" module not found, will be installed"
    Install-Module -Name $UpdatePSModule -Force
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
    Import-Module -Name $UpdatePSModule -Force
    Write-Host (Get-Date -Format $DateTimeFormat)-" module installation sucessful"
    
}
else {
    Write-Host (Get-Date -Format $DateTimeFormat)-" found module $UpdatePSModule version $ModuleVersion" -ForegroundColor Green
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
        Write-Host (Get-Date -Format $DateTimeFormat)-" $FolderName will be removed from C:\" -ForegroundColor Yellow
        Remove-Item -Path $FolderInC.FullName -Recurse -Force
    }
    else {
        Write-Host (Get-Date -Format $DateTimeFormat)-" $FolderName will stay on C:\"
    }
}


###########################################################################
# update drivers
###########################################################################
& $UpdatePrompt

Stop-Transcript