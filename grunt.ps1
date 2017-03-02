# Execute grunt for bundling and minification
#
# Runs the given grunt commands on current directory.
# Installing grunt-cli locally if necessary.
#
# Parameters:
#	node: Path to nodejs executable (if it's not on the system PATH)
#	npm: Path to the npm command (defaults to npm.cmd in the same sirectory as the given node path)
#	grunt_args: commands to execute with grunt (space separated)
#
# Example:
#    ./grunt.ps1 -node:"c:\path_to_node\node.exe" -grunt_args:"command1 command2"
#
param(
[String]$node="node.exe",
[String]$npm="",
[String]$grunt_args="")

try
{
    $commands = $grunt_args.Split(" ")
    if ($commands.Count -eq 0) {
        Write-Host "Skipping grunt (no commands to execute)" -ForegroundColor "green"
        exit 0
    }
	if ($node -ne "node.exe") {
		if (-not (Test-Path $node)) { 
			Write-Host "Nodejs executable not found on", $node -ForegroundColor "red"
			exit -1
		}
		$node_dir = (Get-Item $node).DirectoryName
		Write-Host "Adding directory $node_dir to local PATH"
		$env:Path += ';' + $node_dir
	}
    if (-not (Test-Path "gruntfile.js")) { 
        Write-Host "Gruntfile.js not found on $PSScriptRoot" -ForegroundColor "red"
        exit -1
    }

    Write-Host "Will execute the following", $commands.Count ,"grunt commands:", $commands -ForegroundColor "green"

    & npm config set loglevel error

    Write-Host "Installing grunt-cli locally" -ForegroundColor "green"
    & npm install grunt-cli

    Write-Host "Installing dependencies" -ForegroundColor "green"
    & npm install

    Write-Host "Executing grunt", $commands -ForegroundColor "green"
    & node node_modules\grunt-cli\bin\grunt --stack @commands
}
catch
{
    write-host “Error while trying to execute grunt:” -ForegroundColor Red
    write-host “Exception Type: $($_.Exception.GetType().FullName)” -ForegroundColor Red
    write-host “Exception Message: $($_.Exception.Message)” -ForegroundColor Red
}
