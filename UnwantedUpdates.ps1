###########################################################################
# unwanted updateds
###########################################################################

# need to be identified by id, e.g. sp142036 (HP) or kbwl15rf (Lenovo)
$UnwantedUpdatesByID = @(
    "UnwantedSampleID1", # Sample1
    "UnwantedSampleID2" # Sample2
)

# can be used if updates match a pattern
$UnwantedUpdatesByIDRegex = @(
    "UnwantedSampleRegex1",
    "UnwantedSampleRegex2"
)

# device needs to be identified by (Get-ComputerInfo).Model
# filter acts as Where-Object / possibilities vary by Update-Module (LSUClient / HPDrivers)
$UnwantedUpdatesByDevice = @{
    "82YS" = {$_.Category -eq "Networking Wireless LAN"}
}