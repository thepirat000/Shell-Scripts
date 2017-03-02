# Kill chromedriver.exe and chrome.exe processes
#
# Parameters:
#
#  matchPath: string that must be contained in the file path of the executing chromedriver.exe processes to kill (empty to kill them all)
#  maxDiff: Number of minutes before the current time to kill chrome.exe processes created before that time (0 to kill them all)
#
# For Example:
# cmd /c powershell -noprofile -nologo -executionpolicy Bypass -file Killchrome.ps1 -matchPath:Web.UITest -maxDiff:60
#
param(
[String]$matchPath="Web.UITest",
[Int32]$maxDiff=60
)

$matchProcess = "chrome*" 
$chromeCount = 0
$chromedriverCount = 0
$processes = Get-Process $matchProcess
$now = (GET-DATE)
Write-Host "Kill Chrome - Start -", $processes.Length, "processes before processing"
Write-Host "Match: '$matchPath'. Diff: $maxDiff"
ForEach ($_ in $processes) {
    $path = $_.Path
    $procId = $_.Id
    $name = $_.Name
    $startTime = $_.StartTime
    $diff = [math]::Round((NEW-TIMESPAN –Start $startTime –End $now).TotalMinutes)
    
    if ($name -eq "chromedriver") {
        # Kill chromedriver processes if the path contains the $matchPath string
        if ($path.Contains($matchPath)) {
            Write-Host "Kill CHROMEDRIVER process on $path ($procId)", $startTime, $diff -Foregroundcolor "yellow"
            Stop-Process $procId -Force -erroraction "silentlycontinue"
            $chromedriverCount = $chromedriverCount + 1
        }
        else {
            Write-Host "Skipping CHROMEDRIVER process on $path ($procId)", $startTime, $diff 
        }
    }
    elseif ($name -eq "chrome") {
        # Kill chrome processes that has run for more than $maxDiff minutes
        if ($diff -ge $maxDiff) {
            Write-Host "Kill CHROME process on $path ($procId) running for $diff minutes" -Foregroundcolor "yellow"
            Stop-Process $procId -Force -erroraction "silentlycontinue"
            $chromeCount = $chromeCount + 1
        }
        else {
            Write-Host "Skipping CHROME process ($procId)", $startTime, $diff 
        }
    }
}

$cd1 = If ($chromedriverCount -ge 1) {"es"} Else {""}
$c1 = If ($chromeCount -ge 1) {"es"} Else {""}
Write-Host "Killed $chromeCount chrome process$c1 and $chromedriverCount chromedriver process$cd1" -ForegroundColor "green"

Start-Sleep -m 500

$processes = Get-Process $matchProcess 
Write-Host "Kill Chrome - End -", $processes.Length, "processes after processing"
