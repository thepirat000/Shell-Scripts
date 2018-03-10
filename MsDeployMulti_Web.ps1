#Script parameters:
#
#  serverNames: Comma separated host names or IP addresses of the servers to deploy to
#  packageFile: Relative path to the web package .zip file
#  siteName: IIS site name to deploy
#  appOfflineFile: Absolute path to the app_offine.html template file
#  username: user name to use for deploy
#  password: password to use for deploy
#  environment: environment name for web.config replacement
#  stopOnError: 1 or 0. 1 to indicate the script must stop upon any deployment error. 0 to indicate the script must succeed if at least one server was deployed successfully. (Default is 0).
#  bringNlbOnline: 1 or 0. 1 to rename App_Data\NlbControl.OnlineX to App_Data\NlbControl.Online upon deployment. (Default is 0).
#  switchServerNames: Comma separated host names or IP addresses of the servers that must be switched on/off (i.e. when deploying to BC-Farm put the hostnames of DE-Farm)
#  eventSource: An optional event source name to create on the Event Log of the target servers. (Default is "" meaning no event source will be created)
#
#  MSDEPLOY: MsDeploy.exe path. (default is c:\Program Files (x86)\iis\Microsoft Web Deploy V3\msdeploy.exe).
#
# For Example:
# cmd /c powershell -noprofile -nologo -executionpolicy Bypass -file MsDeployMulti_Web.ps1 -serverNames:"server1,server2,server3" -packageFile:"Package\Bizworks.Report.Web.Framework.zip" -siteName:Bizworks.Report.Web -appOfflineFile:"C:\Tools\app_offline_template.htm" -username:some_user -password:p@ssw0rd -stopOnError:1
#
param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9,\.\-_]+$')][ValidateNotNullOrEmpty()][String]$serverNames='', 
[Parameter(Mandatory=$true)][String]$packageFile='',
[Parameter(Mandatory=$true)][String]$siteName='',
[Parameter(Mandatory=$true)][String]$appOfflineFile='',
[Parameter(Mandatory=$true)][String]$username='',
[Parameter(Mandatory=$true)][String]$password='',
[String]$environment='Debug',
[String]$MSDEPLOY='c:\Program Files (x86)\iis\Microsoft Web Deploy V3\msdeploy.exe',
[int]$stopOnError,
[int]$bringNlbOnline,
[String]$switchServerNames='',
[String]$eventSource=''
) 

function ExecuteMsDeploy_AppOffline ()
{
	$msdeployArguments = 
		'-verb:sync',
		'-allowUntrusted',
		('-source:contentPath="' + $appOfflineFile + '"'),
		('-dest:contentPath=' + $siteName + '/App_offline.htm,computerName="' + $server + '",UserName="' + $username + '",Password="' + $password + '",AuthType="NTLM",includeAcls="False"');

	Write-Host "Will execute MSDEPLOY (APP_OFFINE) with following parameters:" -foregroundcolor "yellow";
	Write-Host "-server =", $server -foregroundcolor "yellow";
	Write-Host "-appOfflineFile =", $appOfflineFile  -foregroundcolor "yellow";
	Write-Host "-siteName =", $siteName  -foregroundcolor "yellow";
	& $MSDEPLOY $msdeployArguments
}

function ExecuteMsDeploy_AppOnline ()
{
	$msdeployArguments = 
		'-verb:delete',
		'-allowUntrusted',
		('-dest:contentPath=' + $siteName + '/App_offline.htm,computerName="' + $server + '",UserName="' + $username + '",Password="' + $password + '",AuthType="NTLM",includeAcls="False"');

	Write-Host "Will execute MSDEPLOY (APP_ONLINE) with following parameters:" -foregroundcolor "yellow";
	Write-Host "-server =", $server -foregroundcolor "yellow";
	Write-Host "-siteName =", $siteName  -foregroundcolor "yellow";
	& $MSDEPLOY $msdeployArguments
}

function ExecuteMsDeploy_Recycle ()
{
	$msdeployArguments = 
		'-verb:sync',
		'-source:recycleApp',
		'-allowUntrusted',
		('-dest:recycleApp=' + $siteName + '/App_offline.htm,computerName="' + $server + '",UserName="' + $username + '",Password="' + $password + '",AuthType="NTLM",includeAcls="False"');

	Write-Host "Will execute MSDEPLOY (RECYCLE) with following parameters:" -foregroundcolor "yellow";
	Write-Host "-server =", $server -foregroundcolor "yellow";
	Write-Host "-siteName =", $siteName  -foregroundcolor "yellow";
	& $MSDEPLOY $msdeployArguments
}

function ExecuteMsDeploy_Package ()
{
	$msdeployArguments = 
		('-source:package="' + $packageFile + '"'),
		('-dest:auto,computerName="' + $server + '",UserName="' + $username + '",Password="' + $password + '",AuthType="NTLM",includeAcls="False"'),
		'-allowUntrusted',
		'-verb:sync',
		'-disableLink:AppPoolExtension',
		'-disableLink:ContentExtension',
		'-disableLink:CertificateExtension',
		'-setParam:name="IIS', 'Web', 'Application', ('Name",value="' + $siteName + '"');

	if ($bringNlbOnline -eq 1) {
		$msdeployArguments += ('-replace:objectName=filePath,match=^NlbControl\.OnlineX,replace=NlbControl.Online');
	}
	
	$msdeployArguments += ('-replace:objectName=filePath,match=Web\.' + $environment + '\.Transformed.config,replace=Web.config');	

	Write-Host "Will execute MSDEPLOY with following parameters:" -foregroundcolor "yellow";
	Write-Host "-server =", $server -foregroundcolor "yellow";
	Write-Host "-packageFile =", $packageFile  -foregroundcolor "yellow";
	Write-Host "-siteName =", $siteName  -foregroundcolor "yellow";
	Write-Host "-bringNlbOnline =", $bringNlbOnline  -foregroundcolor "yellow";
	Write-Host "-environment =", $environment  -foregroundcolor "yellow";
	
	& $MSDEPLOY $msdeployArguments
}

function ExecuteSwitchOn ([String]$hostnames)
{
	Write-Host "Starting SWITCH NLB ON task for servers $hostnames" -foregroundcolor "green";
	
	# Creates the App_Data/NlbControl.Online file on each server
	$hostnames.Split(",") | ForEach {
		$server = $_.Trim();
		$msdeployArguments = 
			'-verb:sync',
			'-allowUntrusted',
			('-source:contentPath="' + $onlineFile + '"'),
			('-dest:contentPath=' + $siteName + '/App_Data/NlbControl.Online,computerName="' + $server + '",UserName="' + $username + '",Password="' + $password + '",AuthType="NTLM",includeAcls="False"');

		Write-Host "Will execute MSDEPLOY (SWITCH NLB ON) on $server" -foregroundcolor "yellow";

		& $MSDEPLOY $msdeployArguments
	}
}

function ExecuteSwitchOff ([String]$hostnames)
{
	Write-Host "Starting SWITCH NLB OFF task for servers $hostnames" -foregroundcolor "green";
	
	# Deletes the App_Data/NlbControl.Online file from each server
	$hostnames.Split(",") | ForEach {
		$server = $_.Trim();
		$msdeployArguments = 
			'-verb:delete',
			'-allowUntrusted',
			('-dest:contentPath=' + $siteName + '/App_Data/NlbControl.Online,computerName="' + $server + '",UserName="' + $username + '",Password="' + $password + '",AuthType="NTLM",includeAcls="False"');

        Write-Host "Will execute MSDEPLOY (SWITCH NLB OFF) on $server" -foregroundcolor "yellow";

        Try 
        {
		    & $MSDEPLOY $msdeployArguments
        }
        Catch 
        {
            if ($_.Exception.Message.Contains("FileOrFolderNotFound")) {
                Write-Host "Skipping file not found exception removing NlbControl.Online on $server" -foregroundcolor "yellow";
            } else {
                Throw;
            }
        }
    }
}

function ExecuteEventSourceCreation ([String]$server)
{
	if ($eventSource.length -gt 0) {
		Write-Host "Will execute event source creation on $server" -foregroundcolor "yellow";
		$passwordSecure = $password | ConvertTo-SecureString -asPlainText -Force
		$credential = New-Object System.Management.Automation.PSCredential($username, $passwordSecure)
		$ScriptBlockContent = { New-EventLog -ComputerName $args[0] -Source "$args[1]" -LogName "Application" -Verbose -ErrorAction Ignore }
        Try 
        {
		    Invoke-Command -ComputerName "$server" -Credential $credential -ScriptBlock $ScriptBlockContent -ArgumentList $server, $eventSource
        }
        Catch 
        {
            Write-Host "Skipping ERROR while executing event source creation on $server :", $_.Exception.Message -foregroundcolor "red";
        }
	}
}

function HandleExitCode ()
{
	Write-Host "Exit Code:", $LastExitCode 
	if ($LastExitCode -ne 0)
	{
		if ($stopOnError -eq 1)
		{
			Write-Host "Error deploying to server", $server -foregroundcolor "red" 
			Exit -1;
		}
		else
		{
			Write-Host "Skipping error deploying to server", $server -foregroundcolor "yellow" 
			$success = 0;
		}
	}
}

$ErrorActionPreference = "Stop"

$totalServers = $serverNames.Split(",").Count;

Write-Host "Start processing package", $packageFile -foregroundcolor "green";
Write-Host "For", $totalServers, "servers" -foregroundcolor "green";

$i = 1;
$ok = 0;
$currentDir = (Get-Location).Path;
$onlineFile = $currentDir + "\NlbControl.Online"

if ($switchServerNames.length -gt 0) {
	Out-File -FilePath $onlineFile
	ExecuteSwitchOn $switchServerNames;
	ExecuteSwitchOff $serverNames;
} else {
	Write-Host "Switch servers not set" -foregroundcolor "green";
}

$serverNames.Split(",") | ForEach {
	Write-Host "Start processing server", $_, "(" , $i, "/", $totalServers, ")" -foregroundcolor "green";
	$server = $_.Trim();
	$success = 1;
	Try
	{
		#Bring the app offline by creating an app_offline file in the root
		ExecuteMsDeploy_AppOffline
		HandleExitCode

		#Recycle the app
		ExecuteMsDeploy_Recycle
		HandleExitCode
		
		#Ensure the event log source is created
		ExecuteEventSourceCreation $server
		
		#Deploy the package
		ExecuteMsDeploy_Package
		HandleExitCode

		#If deployment failed, try to rollback the app_offline change
		if ($LastExitCode -ne 0)
		{
			ExecuteMsDeploy_AppOnline
			HandleExitCode
		} 

		#Recycle the app
		ExecuteMsDeploy_Recycle
		HandleExitCode

		if ($success -eq 1)
		{
			$ok = $ok + 1
		}
	}
	Catch
	{
		if ($stopOnError -eq 1)
		{
			Throw;
		}   
		else
		{
			Write-Host "Skipping exception deploying to server", $server -foregroundcolor "yellow" 
			Write-Host $_.Exception.GetType().FullName, $_.Exception.Message -foregroundcolor "red" 
		}
	}

	Write-Host "End deploying to server", $_
	$i = $i + 1
}

if ($switchServerNames.length -gt 0) {
	if ($bringNlbOnline -ne 1) {
		ExecuteSwitchOn $serverNames;
	}
	ExecuteSwitchOff $switchServerNames;
	Remove-Item -Path $onlineFile
}
 
if ($ok -eq $totalServers)
{
	$color = "green";
}
else
{
	$color = "red";
}

Write-Host "Processed", $ok, "/", $totalServers, "servers successfully" -foregroundcolor $color;

if ($ok -gt 0)
{
	Exit 0
}
else
{
	Exit -1
}

