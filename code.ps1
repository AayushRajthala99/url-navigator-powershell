$urls = Get-Content -Path .\urls.txt

if ($urls.Length -ne 0) {
    
    # Keystrokes Generation Object...
    $wshell = New-Object -ComObject wscript.shell;
    
    # Timestamp, for Unique Identity of Files & Folders...
    $count = 1
    $timestamp = Get-Date -Format "yyyyMMddTHHmmss"
    
    # Directory Generation...
    New-Item ".\recordings\$timestamp" -itemType Directory
    New-Item ".\responses\$timestamp" -itemType Directory
    New-Item ".\screenshots\$timestamp" -itemType Directory

    # Browser Initialization in Incognito Mode... 
    & 'C:\Program Files\Google\Chrome\Application\chrome.exe' --incognito --new-window --start-maximized 'chrome://newtab'

    ForEach ($url in $urls) {
        $url = $url.Trim() # Removes white/blank spaces from URLs...

        #Filename Generation Operation...
        $filename = $url.Replace('https://', '')
        $filename = $filename.Replace('http://', '')
        $filename = $timestamp + "_" + $count + "_" + $filename.Replace('/', '_')
        $count = $count + 1

        # Response Log Generation...
        curl -sSL -D ./responses/$timestamp/$filename.txt $url | Out-Null
        $response = Get-Content -Path .\responses\$timestamp\$filename.txt

        #Flags for Accept-Ranges & Content-Disposition...
        $arFlag = $false
        $cdFlag = $false

        ForEach ($i in $response) {
            if ($i.contains('Accept-Ranges') -and !($i.contains('Accept-Ranges: none'))) {
                $arFlag = $true
            }

            if ($i.contains('content-disposition')) {
                $cdFlag = $true
            }
        }
        
        Start-Sleep -Seconds 1
        & 'C:\Program Files\Google\Chrome\Application\chrome.exe' --incognito --new-tab --start-maximized $url
        Start-Sleep -Seconds 2
        $title = (Get-Process -Name chrome | Select-Object MainWindowTitle)
        ForEach ($i in $title) { if ($i.mainWindowTitle -ne '') { $title = $i.mainWindowTitle; break; } }
        $ffmpegTitle = 'title=' + $title

        # Screen Record Operation...
        ffmpeg -f gdigrab -i $ffmpegTitle -loglevel panic -t 00:00:10.00 -s hd1080 -aspect 16:9 -an -vcodec libx264 .\recordings\$timestamp\$filename.mp4

        # Screenshot Operation...
        ffmpeg -i .\recordings\$timestamp\$filename.mp4 -ss 00:00:09.50 -frames:v 1 -q:v 2 .\screenshots\$timestamp\$filename.jpeg
        
        $wshell.AppActivate($title) | Out-Null
        Start-Sleep -Seconds 1
        $wshell.SendKeys('^w') # Generates 'Ctrl + w' Keystroke...

        # Flags Check for Downloadable-Status...
        if ($arFlag -or $cdFlag) {
            Add-Content .\responses\$timestamp\$filename.txt "`nDownloadable-Status: True"
        }
        else {
            Add-Content .\responses\$timestamp\$filename.txt "`nDownloadable-Status: False"
        }
    }
    Stop-Process -Name chrome
}
else {
    Write-Output '[urls.txt]-File-is-Empty!'
}