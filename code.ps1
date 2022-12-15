$filePath = $args[0]
$duration = $args[1]
$testName = $args[2]

if (($filePath.Length -eq 0) -or ($duration.Length -eq 0) -or ($testName.Length -eq 0)) {
    $message = ''
    if ($filePath.Length -eq 0) { $message = $message + ' <filePath>' }
    if ($duration.Length -eq 0) { $message = $message + ' <RecordDurationinSeconds>' }
    if ($testName.Length -eq 0) { $message = $message + ' <testName>' }
    Write-Output $('--Missing Arguments:' + $message)
    Exit
}

if ($duration -gt 4) {
    $screenshotTime = $duration - 1
    $duration = [timespan]::fromseconds($duration)
    $duration = $duration.ToString("hh\:mm\:ss\.ff")
    $screenshotTime = [timespan]::fromseconds($screenshotTime)
    $screenshotTime = $screenshotTime.ToString("hh\:mm\:ss\.ff")
}
else {
    Write-Output 'Enter Time Greater Than 4 Seconds!'
    Exit
}

$urls = Get-Content -Path $filePath

if ($urls.Length -ne 0) {
    
    Write-Output '[ URL-NAVIGATOR-POWERSHELL ] Developed By Aayush Rajthala!'
    
    # Timestamp, Count for Unique Identity of Files & Folders...
    $count = 1
    $timestamp = Get-Date -Format "yyyyMMddTHHmmss"
    $directoryName = $testName + '_' + $timestamp
    
    # Directory Generation...
    New-Item ".\recordings\$directoryName" -itemType Directory
    New-Item ".\responses\$directoryName" -itemType Directory
    New-Item ".\screenshots\$directoryName" -itemType Directory

    ForEach ($url in $urls) {
        $url = $url.Trim() # Removes white/blank spaces from URLs...

        #Filename Generation Operation...
        $filename = $url.Replace('https://', '')
        $filename = $filename.Replace('http://', '')
        $filename = $count + "_" + $filename.Replace('/', '_')
        $count = $count + 1

        $response = Invoke-WebRequest -Uri $url

        # Flags for Accept-Ranges & Content-Disposition...
        $arFlag = $false
        $cdFlag = $false

        if (($response.Headers.'Accept-Ranges'.Length -gt 0) -and ($response.Headers.'Accept-Ranges'.Contains('none'))) {
            $arFlag = $true    
        }

        if ($response.Headers.'Content-Disposition'.Length -ne 0) {
            $cdFlag = $true
        }

        # Response Log Generation...
        $jsonfile = ".\responses\$directoryName\$filename.json"
        $response | Select-Object -Property StatusCode, StatusDescription, RawContent, Headers | ConvertTo-Json | Out-File $jsonfile
        $response = Get-Content $jsonfile | Out-String | ConvertFrom-Json

        $response | Add-Member -Type NoteProperty -Name 'url' -Value $url
        
        # Flags Check for Downloadable-Status...
        if ($arFlag -or $cdFlag) {
            $response | Add-Member -Type NoteProperty -Name 'Downloadable' -Value 'True'
        }
        else {
            $response | Add-Member -Type NoteProperty -Name 'Downloadable' -Value 'False'
        }
        
        $response | ConvertTo-Json | Set-Content $jsonfile

        Start-Sleep -Seconds 1
        & 'C:\Program Files\Google\Chrome\Application\chrome.exe' --incognito --new-window --start-maximized $url
        Start-Sleep -Seconds 2
        $title = (Get-Process -Name chrome | Select-Object MainWindowTitle)
        ForEach ($i in $title) { if ($i.mainWindowTitle -ne '') { $title = $i.mainWindowTitle; break; } }
        $ffmpegTitle = 'title=' + $title

        # Screen Record Operation...
        ffmpeg -f gdigrab -i $ffmpegTitle -loglevel panic -t $duration -s hd1080 -aspect 16:9 -an -vcodec libx264 .\recordings\$directoryName\$filename.mp4

        # Screenshot Operation...
        ffmpeg -i .\recordings\$directoryName\$filename.mp4 -ss $screenshotTime -frames:v 1 -q:v 2 .\screenshots\$directoryName\$filename.jpeg

        Stop-Process -Name chrome

        $testConfirm = Read-Host -Prompt "Save Test Results? Type [CONFIRM] to CONFIRM: "
        $testConfirm = $testConfirm.ToUpper()
        $confirmDecision = Read-Host -Prompt "Are You Sure? [Y/N]: "
        $confirmDecision = $confirmDecision.ToUpper()

        if (($testConfirm -eq 'CONFIRM') -and ($confirmDecision -eq 'Y')) {
            Write-Output $('--' + $testName + ' Test Completed!')
            Exit
        }
        else {
            Remove-Item ".\recordings\$directoryName" -Recurse
            Remove-Item ".\responses\$directoryName" -Recurse
            Remove-Item ".\screenshots\$directoryName" -Recurse
            Write-Output $($testName + 'Test Discarded!')
            Exit
        }
    }
}
else {
    Write-Output $('--[ ' + $filePath + ' ]--File is Empty!!!')
    Exit
}