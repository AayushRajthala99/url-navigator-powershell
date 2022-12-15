$filePath = $args[0]
$duration = $args[1]
$testName = $args[2]

if (($filePath.Length -eq 0) -or ($duration.Length -eq 0) -or ($testName.Length -eq 0)) {
    $message = ''
    if ($filePath.Length -eq 0) { $message = $message + ' <filePath>' }
    if ($duration.Length -eq 0) { $message = $message + ' <RecordDurationinSeconds>' }
    if ($testName.Length -eq 0) { $message = $message + ' <testName>' }
    Write-Output $('--Missing Arguments:' + $message + '--')
    # Exit
}

Write-Output $('--[ ' + $filePath + ' ]--File is Empty!!!')