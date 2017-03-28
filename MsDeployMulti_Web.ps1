#Script parameters:
#
#  serverNames: Comma separated host names or IP addresses of the servers to deploy to
#  packageFile: Relative path to the web package .zip file
#  siteName: IIS site name to deploy
#  username: user name to use for deploy
#  password: password to use for deploy
#  stopOnError: 1 or 0. 1 to indicate the script must stop upon any deployment error. 0 to indicate the script must succeed if at least one server was deployed successfully. (Default is 0).
#  MSDEPLOY: MsDeploy.exe path. (default is c:\Program Files (x86)\iis\Microsoft Web Deploy V3\msdeploy.exe).
#
# For Example:
# cmd /c powershell -noprofile -nologo -executionpolicy Bypass -file MsDeployMulti_Web.ps1 -serverNames:"server1,server2,server3" -packageFile:"Package\YourPackage.zip" -siteName:YourSiteName -username:some_user -password:p@ssw0rd -stopOnError:1
#
param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9,\.\-_]+$')][ValidateNotNullOrEmpty()][String]$serverNames='', 
[Parameter(Mandatory=$true)][String]$packageFile='',
[Parameter(Mandatory=$true)][String]$siteName='',
[Parameter(Mandatory=$true)][String]$username='',
[Parameter(Mandatory=$true)][String]$password='',
[String]$MSDEPLOY='c:\Program Files (x86)\iis\Microsoft Web Deploy V3\msdeploy.exe',
[int]$stopOnError
) 

function ExecuteMsDeploy ()
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

    Write-Host "Will execute MSDEPLOY with following parameters:" -foregroundcolor "yellow";
    Write-Host "-server =", $server -foregroundcolor "yellow";
    Write-Host "-packageFile =", $packageFile  -foregroundcolor "yellow";
    Write-Host "-siteName =", $siteName  -foregroundcolor "yellow";
    & $MSDEPLOY $msdeployArguments
}

$ErrorActionPreference = “Stop”

$totalServers = $serverNames.Split(",").Count;

Write-Host "Start processing package", $packageFile -foregroundcolor "green";
Write-Host "For", $totalServers, "servers" -foregroundcolor "green";

$i = 1;
$ok = 0;

 $serverNames.Split(",") | ForEach {
    Write-Host "Start processing server", $_, "(" , $i, "/", $totalServers, ")" -foregroundcolor "green";
    $server = $_.Trim();

    Try
    {
        ExecuteMsDeploy
        Write-Host "Exit Code:", $LastExitCode 
        if ($LastExitCode -eq 0)
        {
            $ok = $ok + 1
        }
        else
        {
            if ($stopOnError -eq 1)
            {
                Write-Host "Error deploying to server", $server -foregroundcolor "red" 
                Exit -1;
            }
            else
            {
                Write-Host "Skipping error deploying to server", $server -foregroundcolor "yellow" 
            }
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

    Write-Host "End processing server", $_
    $i = $i + 1
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

