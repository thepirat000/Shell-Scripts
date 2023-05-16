# Will copy the added and modified files in the current local copy of a GIT repository to the specified target folder.
if (-not(test-path .git)) {
    Write-host "Not in a GIT repository" -ForegroundColor Yellow
    return
}

$targetRootDir = (Split-Path -Path $pwd.Path -Parent) + "\" + (Split-Path -Path $pwd.Path -Leaf) + "_bkp_" + (Get-Date).ToString("yyyy-MM-dd_HHmmss")

Write-host $targetRootDir -ForegroundColor Yellow

if (test-path $targetRootDir) {
    Write-host "Destination directory exists", $targetRootDir -ForegroundColor Yellow
    return
}

New-Item -Path $targetRootDir -ItemType Directory

git status --porcelain | ForEach-Object { 
    $sourceFile = $_.Trim().SubString(1).Trim().Replace("/", "\")
    
    $lastBackSlashIndex = $sourceFile.LastIndexOf("\");
    $folder = if ($lastBackSlashIndex -eq -1) { "" } else { $sourceFile.Substring(0, $lastBackSlashIndex) }
    $targetDir = $targetRootDir + "\" + $folder
    $filename = if ($lastBackSlashIndex -eq -1) { $sourceFile } else { $sourceFile.Substring($lastBackSlashIndex + 1) }
    $targetFilePath = $targetDir + "\" + $filename;
    
    Write-Host $targetFilePath

    If (Test-Path -Path $sourceFile) {
        New-Item -ItemType File -Path $targetFilePath -Force
        Copy-Item $sourceFile -Destination $targetDir
    } 
    Else {
        Write-Host $sourceFile, "Does not exists!" -ForegroundColor Yellow
    }
}

if (( Get-ChildItem $targetRootDir | Measure-Object ).Count -eq 0) {
    Remove-Item -Path $targetRootDir
}

Write-Host $targetRootDir -ForegroundColor Green
