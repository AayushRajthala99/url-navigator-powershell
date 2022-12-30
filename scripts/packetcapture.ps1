$pcapFLag = $args[0]
$pcapInterface = $args[1]
$directoryName = $args[2]
$filename = $args[3]

$packetcapturePath = ".\results\$directoryName\packetcaptures"

if ($pcapFLag -eq 1) {
    $pcapFilePath = "$packetcapturePath\$filename.pcap"
    tshark -i $pcapInterface -w $pcapFilePath
}

if ($pcapFLag -eq 0) {
    Get-Job | Stop-Job
    Remove-Job *
}