$filePath = $args[0]
$testName = $args[1]
$duration = $args[2]

$defaultDuration = 5 # Default Duration Set to 5 Seconds...

if (($filePath.Length -eq 0) -or ($testName.Length -eq 0)) {
    $message = ''
    if ($filePath.Length -eq 0) { $message = $message + ' <filePath>' }
    if ($testName.Length -eq 0) { $message = $message + ' <testName>' }
    Write-Output $('--Missing Arguments:' + $message)
    Exit
}

if (!$filePath.Contains('.txt')) {
    Write-Output $('--Invalid File Type: Use *.txt Files Only!')
    Exit
}

if ($duration.Length -gt 0) {
    if ($duration -lt $defaultDuration) {
        Write-Output $('--Duration < ' + $defaultDuration + ' Seconds: Duration set to Default Values [ ' + $defaultDuration + ' Seconds ]')
        $duration = $defaultDuration
    }
}
else {
    Write-Output $('--Duration Argument Missing: Duration set to Default Values [ ' + $defaultDuration + ' Seconds ]')
    $duration = $defaultDuration
}

# Screen Record & Screenshot Duration Calulation..
$screenshotTime = $duration - 1
$duration = [timespan]::fromseconds($duration)
$duration = $duration.ToString("hh\:mm\:ss\.ff")
$screenshotTime = [timespan]::fromseconds($screenshotTime)
$screenshotTime = $screenshotTime.ToString("hh\:mm\:ss\.ff")

$urls = Get-Content -Path $filePath

if ($urls.Length -ne 0) {
    
    Write-Output '[ URL-NAVIGATOR-POWERSHELL ] Developed By Aayush Rajthala!'

    tshark -D
    $pcapInterface = Read-Host -Prompt "Select Packet Capture Interface: "

    # Keystrokes Generation Object...
    # $wshell = New-Object -ComObject wscript.shell;
    
    # Timestamp, Count for Unique Identity of Files & Directories...
    $count = 1
    $date = Get-Date -UFormat "%b-%d-%Y"
    $time = Get-Date -Format "HH\H-mm\m-ss\s"
    $timestamp = $date + '-' + $time
    $directoryName = $testName + '_' + $timestamp
    
    # Directory Generation...
    if (!(Test-Path -Path ".\results")) {
        New-Item ".\results" -itemType Directory    
    }
    if (!(Test-Path -Path ".\discardedResults")) {
        New-Item ".\discardedResults" -itemType Directory    
    }
    New-Item ".\results\$directoryName" -itemType Directory
    New-Item ".\results\$directoryName\recordings" -itemType Directory
    New-Item ".\results\$directoryName\responses" -itemType Directory
    New-Item ".\results\$directoryName\screenshots" -itemType Directory
    New-Item ".\results\$directoryName\packetcaptures" -itemType Directory

    $recordingPath = ".\results\$directoryName\recordings"
    $responsePath = ".\results\$directoryName\responses"
    $screenshotPath = ".\results\$directoryName\screenshots"
    $packetcapturePath = ".\results\$directoryName\packetcaptures"

    ForEach ($url in $urls) {
        $url = $url.Trim() # Removes white/blank spaces from URLs...
        
        if ($url.Length -gt 0) {
            #Filename Generation Operation...
            $fileCount = [string]$count
            $filename = $url.Replace('https://', '')
            $filename = $filename.Replace('http://', '')
            $filename = $filename.Replace('/', '_')
            $filename = $filename -replace '[^a-zA-Z0-9.]', ''
            $filename = $fileCount + '_' + $filename
            $count = $count + 1

            $pcapFilePath = "$packetcapturePath\$filename" + '.pcap'
            tshark -i $pcapInterface -w $pcapFilePath &
            
            # Browser Initialization in Incognito Mode... 
            Start-Sleep -Seconds 1
            & "chrome.exe" --incognito --new-window --disable-web-security --ignore-certificate-errors --start-maximized $url
            Start-Sleep -Seconds 2
            
            $title = (Get-Process -Name chrome | Select-Object MainWindowTitle)
            ForEach ($i in $title) { if ($i.mainWindowTitle -ne '') { $title = $i.mainWindowTitle; break; } }
            $ffmpegTitle = 'title=' + $title

            # Screen Record Operation...
            ffmpeg -f gdigrab -framerate 12 -i $ffmpegTitle -loglevel error -t $duration -s hd1080 -aspect 16:9 -an -vcodec libx264 $recordingPath\$filename.mp4

            # Screenshot Operation...
            ffmpeg -i $recordingPath\$filename.mp4 -ss $screenshotTime -frames:v 1 -q:v 2 $screenshotPath\$filename.jpeg
            
            $response = Invoke-WebRequest -SkipHeaderValidation -SkipHttpErrorCheck -SkipCertificateCheck $url

            # Flags for Accept-Ranges & Content-Disposition...
            $arFlag = $false
            $cdFlag = $false
            $ctFlag = $false
    
            if (($response.Headers.'Accept-Ranges'.Length -gt 0) -and !($response.Headers.'Accept-Ranges'.Contains('none'))) {
                $arFlag = $true
            }

            if ($response.Headers.'Content-Type'.Length -gt 0) {
                $ctFlag = $true
            }
    
            if ($response.Headers.'Content-Disposition'.Length -ne 0) {
                $cdFlag = $true
            }
    
            # Response Log Generation...
            $jsonfile = "$responsePath\$filename.json"
            $response | Select-Object -Property StatusCode, StatusDescription, RawContent, Headers | ConvertTo-Json | Out-File $jsonfile
            $response = Get-Content $jsonfile | Out-String | ConvertFrom-Json
    
            if ($null -ne $response) {
                $response | Add-Member -Type NoteProperty -Name 'url' -Value $url
            
                # Flags Check for Downloadable-Status...
                if ($arFlag -or $cdFlag -or $ctFlag) {
                    $response | Add-Member -Type NoteProperty -Name 'Downloadable' -Value 'True'
                }
                else {
                    $response | Add-Member -Type NoteProperty -Name 'Downloadable' -Value 'False'
                }
            
                $response | ConvertTo-Json | Set-Content $jsonfile
            }
            else {
                "{'url': $url,'status': 'No Response'}" > $jsonfile
            }

            Get-Job | Stop-Job
            Remove-Job *
            Stop-Process -Name chrome
        }
    }

    # Test Confirm/Discard Operation...
    $discardConfirm = Read-Host -Prompt "DISCARD TEST? Type [DISCARD] to DISCARD: "
    $discardConfirm = $discardConfirm.ToUpper()
    
    if ($discardConfirm -eq 'DISCARD') {
        $confirmDecision = Read-Host -Prompt "Are You Sure? [Y/N]: "
        $confirmDecision = $confirmDecision.ToUpper()
        
        if ($confirmDecision -eq 'Y') {
            # Move All Results if Test Discarded...
            # Remove-Item ".\results\$directoryName" -Recurse -Force
            Move-Item ".\results\$directoryName" -Destination ".\discardedResults\"
            Write-Output $('--' + $testName + ' Test Discarded!')
            Exit
        }
    }
    else {
        Copy-Item ".\urls.txt" -Destination ".\results\$directoryName\"
        Write-Output $('--' + $testName + ' Test Completed!')
        Exit
    }
}
else {
    Write-Output $('--[ ' + $filePath + ' ]--File is Empty!!!')
    Exit
}