# Script to install an extra GoCD agent on windows
#
# Usage:
#   ./InstallGoAgent.ps1 -source_path "c:\GoAgent" -agent_path "c:\GoAgent2" -agent_name "GoAgent2"
#
# Params:
#   source_path: The source path of an existing working agent (i.e. "C:\Program Files\Go Agent")
#   agent_path: The destination path for the new agent (i.e. "C:\GoAgent2")
#   agent_name: The name of the windows service for the new agent (i.e. "GoAgent2")
#
param(
[String]$source_path=$PSScriptRoot, 
[String]$agent_path, 
[String]$agent_name) 

$testFile = Join-Path $source_path 'cruisewrapper.exe'

if ($agent_path -eq '') {
    Write-Host "Please specify -agent_path" -ForegroundColor "red";
    exit -1
}

if (-not (Test-Path "$testFile")) { 
    Write-Host "File", $testFile, "does not exists"
    exit -1
}

if (Test-Path "$agent_path") {
    Write-Host "New agent path", $agent_path, "already exists" -ForegroundColor "red";
    exit -1
}

if (Get-Service -Name "$agent_name" -ErrorAction SilentlyContinue)
{
    Write-Host "Windows service", $agent_name, "already exists. Run `"sc.exe delete $agent_name`" to remove the service." -foregroundcolor "red";
    exit -1
}


# Copy GoAgent to new folder
Write-Host "Copying GoAgent to new folder", $agent_path -foregroundcolor "green";
$logfile = $PSScriptRoot + '\GoAgent_Copy.log';
$exclude1 = Join-Path $source_path 'data'
$exclude2 = Join-Path $source_path 'pipelines'
robocopy "$source_path" "$agent_path" /MIR /Z /LOG:$logfile /XF *.log guid.txt .agent-bootstrapper.running /XD "$exclude1" "$exclude2"

$configFile = Join-Path $agent_path 'config\wrapper-agent.conf'

# Replace/Insert "set.GO_AGENT_DIR=" on config file
if (Get-Content $configFile | Select-String -Pattern "^set\.GO_AGENT_DIR=.+$") {
    Write-Host "Replacing agent dir on config file", $configFile -foregroundcolor "green";
    (Get-Content "$configFile") | Foreach-Object {$_ -replace '^set\.GO_AGENT_DIR=.+$', "set.GO_AGENT_DIR=$agent_path"} | Set-Content "$configFile"
} else {
    Write-Host "Writing agent dir on config file", $configFile -foregroundcolor "green";
    $replacement = "`$1`n`n#========================================`nset.GO_AGENT_DIR=" + $agent_path + "`nset.GO_AGENT_JAVA_HOME=%GO_AGENT_DIR%\jre`n#========================================`n`n"
    (Get-Content "$configFile") | Foreach-Object {$_ -replace '^(#include\s*.+)$', $replacement} | Set-Content "$configFile"
}

# Replace agent service name on agent.cmd net stop
Write-Host "Replacing agent service name on agent.cmd file.", $agent_name -foregroundcolor "green";
$agentCmd = Join-Path $agent_path 'agent.cmd'
(Get-Content "$agentCmd") | Foreach-Object {$_ -replace '^(if %STOP_BEFORE_STARTUP% == Y net stop)\s+(.+)$', "`$1 `"$agent_name`""} | Set-Content "$agentCmd"

# Create the windows service
$cruiseFile = Join-Path $agent_path 'cruisewrapper.exe'
$targetPath = "$cruiseFile -s $configFile"
Write-Host "Creating the windows service", $agent_name, "with binPath", $cruiseFile -foregroundcolor "green";
sc.exe create $agent_name binPath= "$cruiseFile -s $configFile" start=auto

# Starting the windows service
Write-Host "Starting the windows service", $agent_name -foregroundcolor "green";
net start $agent_name

