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