# Will copy the added and modified files in the current local copy of a GIT repository to the specified target folder.
$targetRootDir = "C:\Temp"

git status --porcelain | ForEach-Object { 
    $sourceFile = $_.Trim().SubString(1).Trim().Replace("/", "\")
    
    $targetDir = $targetRootDir + "\" + $sourceFile.Substring(0, $sourceFile.LastIndexOf("\"))
    $filename = $sourceFile.Substring($sourceFile.LastIndexOf("\") + 1)
    $targetFilePath = $targetDir + "\" + $filename;
    
    Write-Host $targetFilePath
    New-Item -ItemType File -Path $targetFilePath -Force
    Copy-Item $sourceFile -Destination $targetDir
}
