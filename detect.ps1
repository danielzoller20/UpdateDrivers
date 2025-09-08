$PackageName = "UpdateDrivers"
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-detect.log" -Force
$ErrorActionPreference = "Stop"


$TestsSucessful = 0

# first file to check for presence and for filesize
$FilePathToTest = "C:\Program Files\UpdateDrivers\UpdateDrivers.ps1"
$SpecifiedLenght = 10294
if (Test-Path $FilePathToTest) {
    Write-Host "$FilePathToTest present" -ForegroundColor Green
    $TestsSucessful++
}
else {
    Write-Host "$FilePathToTest not present" -ForegroundColor Red
}
if ((Get-ItemProperty $FilePathToTest).Length -eq $SpecifiedLenght) {
    Write-Host "$FilePathToTest filesize as specified" -ForegroundColor Green
    $TestsSucessful++
}
else {
    Write-Host "$FilePathToTest filesize not as specified" -ForegroundColor Red
}


# second file to check for presence and for filesize
$FilePathToTest = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Treiber aktualisieren.lnk"
$SpecifiedLenght = 1225
if (Test-Path $FilePathToTest) {
    Write-Host "$FilePathToTest present" -ForegroundColor Green
    $TestsSucessful++
}
else {
    Write-Host "$FilePathToTest not present" -ForegroundColor Red
}
if ((Get-ItemProperty $FilePathToTest).Length -eq $SpecifiedLenght) {
    Write-Host "$FilePathToTest filesize as specified" -ForegroundColor Green
    $TestsSucessful++
}
else {
    Write-Host "$FilePathToTest filesize not as specified" -ForegroundColor Red
}


$NumberOfTests = 4
if ($TestsSucessful -eq $NumberOfTests) {
    Write-Host "`r`nall $NumberOfTests tests passed" -ForegroundColor Green
    Stop-Transcript
    exit(0)
}
else {
    Write-Host "`r`nnot all $NumberOfTests tests were passed" -ForegroundColor Red
    Stop-Transcript
    exit(1)
}