###########################################################################
# unwanted updateds
###########################################################################

# need to be identified by id, e.g. sp142036 (HP) or kbwl15rf (Lenovo)
$UnwantedUpdatesByID = @(
    "UnwantedSampleID1", # Sample1
    "UnwantedSampleID2" # Sample2
)

$UnwantedUpdatesByIDRegex = @(
    "UnwantedSampleRegex1",
    "UnwantedSampleRegex2"
)

$UnwantedUpdatesByDevice = @{
    "82YS" = {$_.Category -ne "Networking Wireless LAN"}
}