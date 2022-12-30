$filePath = $args[0]
$testName = $args[1]
$duration = $args[2]

$defaultDuration = 5 # Default Duration Set to 5 Seconds...
$ErrorActionPreference = "SilentlyContinue"

if (($filePath.Length -eq 0) -or ($testName.Length -eq 0)) {
    $message = ''
    if ($filePath.Length -eq 0) { $message = $message + ' <filePath>' }
    if ($testName.Length -eq 0) { $message = $message + ' <testName>' }
    Write-Output "--ERROR--Missing Arguments: $message"
    Exit
}

if (!$filePath.Contains('.txt')) {
    Write-Output '--ERROR--Invalid File Type: Use *.txt Files Only!'
    Exit
}

if ($duration.Length -gt 0) {
    if ($duration.GetType().Name -ne 'Int32') {
        Write-Output '--ERROR--Duration Value Must be Int32 Type'
        Exit
    }

    if ($duration -lt $defaultDuration) {
        Write-Output "--ERROR--Duration < $defaultDuration Seconds: Duration set to Default Values [ $defaultDuration Seconds ]"
        $duration = $defaultDuration
    }
}
else {
    Write-Output "--ERROR--Duration Argument Missing: Duration set to Default Values [ $defaultDuration Seconds ]"
    $duration = $defaultDuration
}

# Screen Record & Screenshot Duration Calulation..
$responseTimeout = $duration - 1
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
    $timestamp = "$date-$time"
    $directoryName = $testName + '_' + $timestamp
    
    Write-Output "Directory Generation in Progess!!!"
    ./scripts/directorygeneration.ps1 $directoryName
    Write-Output "Directory Generation in Progess!!!"
    
    $recordingPath = ".\results\$directoryName\recordings"
    $responsePath = ".\results\$directoryName\responses"
    $screenshotPath = ".\results\$directoryName\screenshots"

    ForEach ($url in $urls) {
        try {
            $url = $url.Trim() # Removes white/blank spaces from URLs...
        
            if ($url.Length -gt 0) {

                # Clear Console Screen
                Clear-Host

                #Filename Generation Operation...
                $fileCount = [string]$count
                $filename = $url.Replace('https://', '')
                $filename = $filename.Replace('http://', '')
                $filename = $filename.Replace('/', '_')
                $filename = $filename -replace '[^a-zA-Z0-9.]', ''
                $filename = $fileCount + '_' + $filename
                $count = $count + 1

                Write-Output "Response Generation Operation Started!!!"
                ./scripts/response.ps1 $responsePath $filename $url $responseTimeout &
                
                Write-Output "Packet Capture Operation Started!!!"
                ./scripts/packetcapture.ps1 1 $pcapInterface $directoryName $filename &
            
                Write-Output "Browser Navigation Started!!!"
                # Browser Initialization in Incognito Mode... 
                & "chrome.exe" --incognito --new-window --start-maximized $url
                Write-Output "Navigating to: $url"
                
                Write-Output "Getting Window Title!!!"
                Start-Sleep -Seconds 2.5
                $title = (Get-Process -Name chrome | Select-Object MainWindowTitle)
                ForEach ($i in $title) { if ($i.mainWindowTitle -ne '') { $title = $i.mainWindowTitle; break; } }
                $ffmpegTitle = 'title=' + $title
                Write-Output "Got Browser Title: $ffmpegTitle"

                Write-Output "Screen Recording in Progess!!!"
                # Screen Record Operation...
                ffmpeg -f gdigrab -framerate 12 -i $ffmpegTitle -loglevel error -t $duration -s hd1080 -aspect 16:9 -an -vcodec libx264 $recordingPath\$filename.mp4
                Write-Output "Screen Recording Completed!!!"
                
                Write-Output "Screenshot in Progess!!!"
                # Screenshot Operation...
                ffmpeg -i $recordingPath\$filename.mp4 -ss $screenshotTime -frames:v 1 -q:v 2 $screenshotPath\$filename.jpeg
                Write-Output "Screenshot Taken!!!"

                ./scripts/packetcapture.ps1 0
                Write-Output "Ended Packet Capture Operation!!!"
                
                Stop-Process -Name chrome
                Write-Output "Chrome Process Ended!!!"
            }
        }
        catch {
            Write-Output "--ERROR--Exception Caught For $url"
        }
    }

    # Clear Console Screen
    Clear-Host

    # Test Confirm/Discard Operation...
    $discardConfirm = Read-Host -Prompt "DISCARD TEST? Type [DISCARD] to DISCARD: "
    $discardConfirm = $discardConfirm.ToUpper()
    
    if ($discardConfirm -eq 'DISCARD') {
        $confirmDecision = Read-Host -Prompt "Are You Sure? [Y/N]: "
        $confirmDecision = $confirmDecision.ToUpper()
        
        if (($confirmDecision -eq 'Y') -or ($confirmDecision -eq '')) {
            # Move All Results if Test Discarded...
            Copy-Item ".\urls.txt" -Destination ".\results\$directoryName\"
            Move-Item ".\results\$directoryName" -Destination ".\discardedResults\"
            Write-Output "--[ $testName ]--Test Discarded!"
            Exit
        }
    }
    else {
        Copy-Item ".\urls.txt" -Destination ".\results\$directoryName\"
        Write-Output "--[ $testName ]--Test Completed!"
        Exit
    }
}
else {
    Write-Output "--ERROR--[ $filePath ]--File is Empty!!!"
    Exit
}