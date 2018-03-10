# Patch the versions of the assemblies (AssemblyInfo.cs) to the following format: Major.Minor.Patch.Rev
# Being: 
#    Major: The given Product Version major version number. When productVersion is "*" the assembly major number is not changed.
#    Minor: The given Product Version minor version number. When productVersion is "*" the assembly minor number is not changed.
#    Patch: The current TFS build number
#    Rev: The current TFS build revision number
#
# Parameters:
#    productVersion: The current product version in format Major.Minor.Patch. i.e. "1.0.0", or asterisk "*" to leave the current major.minor untouched.
#    srcPath: (Optional) The root path to search for AssemblyInfo.cs files, if not given, the current directory is used.
Param
(
    [Parameter(Mandatory=$true)][string]$productVersion,
    [string]$srcPath=$null
)
     
$buildNumber = $env:BUILD_BUILDNUMBER
if ($buildNumber -eq $null)
{
    $strDay = (Get-Date).DayofYear
    $year = (Get-Date).ToString("yy")
    $buildNumber = "$year$strDay.0"
}
$matches = [regex]::matches($buildNumber, "\D*(\d+)\.(\d+)")
$patch = $matches.Groups[1].value
$rev = $matches.Groups[2].value

if ($srcPath -eq $null) 
{
    $srcPath = $PSScriptRoot
}
Write-Verbose "Executing Update-AssemblyInfoVersionFiles in path '$srcPath' for product version Version $productVersion"  -Verbose
 
Write-Verbose "Patch: $patch - Rev: $rev" -Verbose

#split product version in SemVer language
if ($productVersion -ne "*") {
    $versions = $productVersion.Split('.')
    $major = $versions[0]
    $minor = $versions[1]

    $assemblyFileVersion = "$major.$minor.$patch.$rev"
    $assemblyVersion = $productVersion
    $assemblyInformationalVersion = $productVersion
     
    Write-Verbose "Assembly Version is $assemblyVersion" -Verbose
    Write-Verbose "Assembly File Version is $assemblyFileVersion" -Verbose
    Write-Verbose "Assembly Informational Version is $assemblyInformationalVersion" -Verbose
}

$AllVersionFiles = Get-ChildItem -path $srcPath -recurse -include "AssemblyInfo.cs","project.json"

$fileCount = $AllVersionFiles.Count
Write-Verbose "Processing $fileCount files." -Verbose

foreach ($file in $AllVersionFiles) 
{ 
	#version replacements
    $fileName = $file.FullName
    if ($file.Name.ToLower() -eq "assemblyinfo.cs")
    {
        if ($productVersion -eq "*") 
        {
            (Get-Content $fileName) |
            %{$_ -replace 'AssemblyDescription\(""\)', "AssemblyDescription(""assembly built by TFS Build $buildNumber"")" } |
            %{$_ -replace 'AssemblyFileVersion\("([0-9]+)\.([0-9]+)(\.([0-9]+|\*)){1,2}"\)', "AssemblyFileVersion(""`$1.`$2.$patch.$rev"")" } |
	        Set-Content $fileName -Force
        } 
        else 
        {
            (Get-Content $fileName) |
            %{$_ -replace 'AssemblyDescription\(""\)', "AssemblyDescription(""assembly built by TFS Build $buildNumber"")" } |
            %{$_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyVersion(""$assemblyVersion"")" } |
            %{$_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyFileVersion(""$assemblyFileVersion"")" } |
	        %{$_ -replace 'AssemblyInformationalVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyInformationalVersion(""$assemblyInformationalVersion"")" } | 
	        Set-Content $fileName -Force
        }
    }
    if ($file.Name.ToLower() -eq "project.json")
    {
        if ($productVersion -eq "*") 
        {
            (Get-Content $fileName) |
	        %{$_ -replace '"version":\s*"([0-9]+)\.([0-9]+)(\.([0-9]+|\*)){1,2}"', """version"": ""`$1.`$2.$patch.$rev""" } | 
	        Set-Content $fileName -Force
        }
        else
        {
            (Get-Content $fileName) |
	        %{$_ -replace '"version":\s*"[0-9]+(\.([0-9]+|\*)){1,3}"', """version"": ""$assemblyFileVersion""" } | 
	        Set-Content $fileName -Force
        }
    }
    Write-Verbose "Processed: $fileName" -Verbose
}

return $assemblyFileVersion
