$urls = Get-Content -Path .\urls.txt

if ($urls.Length -ne 0) {
    
    # Keystrokes Generation Object...
    $wshell = New-Object -ComObject wscript.shell;
    
    # Timestamp for Unique Identity of Files & Folders...
    $timestamp = Get-Date -Format "yyyyMMddTHHmmss"
    
    # Directory Generation...
    New-Item ".\recordings\$timestamp" -itemType Directory
    New-Item ".\responses\$timestamp" -itemType Directory
    New-Item ".\screenshots\$timestamp" -itemType Directory

    # Browser Initialization in Incognito Mode... 
    & 'C:\Program Files\Google\Chrome\Application\chrome.exe' --incognito --new-tab --start-maximized 'chrome://newtab'

    ForEach ($url in $urls) {
        $url = $url.Trim() # Removes white/blank spaces from URLs...

        #Filename Generation Operation...
        $filename = $url.Replace('https://', '')
        $filename = $timestamp + "_" + $filename.Replace('/', '_')

        #Screen Capture...
        $response = $(curl -sSL -D ./responses/$timestamp/$filename.txt $url)
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

        & 'C:\Program Files\Google\Chrome\Application\chrome.exe' --incognito --new-tab --start-maximized $url
        Start-Sleep -Seconds 1
        
        $title = (get-process chrome | Select-Object MainWindowTitle)
        ForEach ($i in $title) { if ($i.mainWindowTitle -ne '') { $title = $i.mainWindowTitle; break; } }
        $title = 'title=' + $title

        # Screen Record Operation...
        ffmpeg -f gdigrab -i $title -loglevel panic -t 00:00:05.00 -vf crop=1920:992:0:88 -vcodec libx264 .\recordings\$timestamp\$filename.mp4

        # Screenshot Operation...
        ffmpeg -ss 00:00:04.90 -i .\recordings\$timestamp\$filename.mp4 -frames:v 1 .\screenshots\$timestamp\$filename.jpg
        
        $wshell.SendKeys('^w') # Generates 'Ctrl + w' Keystroke...
        Start-Sleep -Seconds 1

        # Flags Check for Downloadable-Status...
        if ($arFlag -or $cdFlag) {
            Add-Content .\responses\$timestamp\$filename.txt "`nDownloadable-Status: True"
            Write-Output $url Downloadable
        }
        else {
            Add-Content .\responses\$timestamp\$filename.txt "`nDownloadable-Status: False"
            Write-Output $url NotDownloadable
        }
    }
    Stop-Process -Name chrome
}
else {
    Write-Output '[urls.txt]-File-is-Empty!'
}