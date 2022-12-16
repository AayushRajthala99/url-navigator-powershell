# Screen Record Automation using Powershell & FFMPEG

(o) Objective:

- To Record Screen & capture Screenshots of URLs listed in a .txt file via Powershell & FFMPEG.
- Capture Header Responses as Logs for each URLs.

(o) Done:

- Added Screen Record & Screenshot Functionality after browser navigation to URL.
- Record Header Responses in './responses/' based on timestamps.

(o) Pre-requisites:

FFMPEG

```
https://ffmpeg.org/download.html
```

(Note: Set Environment Variable [User] Path for FFMPEG.exe :: https://www.wikihow.com/Install-FFmpeg-on-Windows)
<br><br>
POWERSHELL >= v7.0

```
https://learn.microsoft.com/en-us/powershell/
```

GOOGLE CHROME BROWSER

```
https://www.google.com/chrome/
```

To Execute the Script

```shell
PS> ./code.ps1 <filePath> <testName> <screenRecordDurationInSeconds>[Enter]
```
