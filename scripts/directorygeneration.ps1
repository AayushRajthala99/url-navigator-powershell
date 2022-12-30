$directoryName = $args[0]

# Directory Generation...
if (!(Test-Path -Path ".\discardedResults")) {
    New-Item ".\discardedResults" -itemType Directory    
}
if (!(Test-Path -Path ".\results")) {
    New-Item ".\results" -itemType Directory    
}
Start-Sleep -Seconds 1
New-Item ".\results\$directoryName" -itemType Directory
New-Item ".\results\$directoryName\recordings" -itemType Directory
New-Item ".\results\$directoryName\responses" -itemType Directory
New-Item ".\results\$directoryName\screenshots" -itemType Directory
New-Item ".\results\$directoryName\packetcaptures" -itemType Directory