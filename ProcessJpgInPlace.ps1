# Will JPEG compress (quality ~80%) and replace in-place all the images on the current folder and subfolders
# Keeping the same image dimension, dates and metadata
# Will process only image files > 0.5MB

$savedSpace = 0
$counter = 0
$tmpDir = "D:\Temp\img-proc\" 

if (-not(Test-Path $tmpDir)) {
    New-Item $tmpDir -ItemType Directory
}

$files = Get-ChildItem ./ -include *.jp*g -recurse | where-object {$_.length -gt 0.5MB} | Sort-Object -Property Name

$outDir = Join-Path -Path $tmpDir -ChildPath (Get-Date -Format "yyyy_MM_dd_HHmmss")

if (-not(Test-Path $outDir)) {
    New-Item $outDir -ItemType Directory
}

for ($i=0; $i -lt $files.Count; $i++) {
    $f = $files[$i]
    $outfile = Join-Path -Path $outDir -ChildPath $f.Name
    
    $perc = [math]::Round($i * 100 / $files.Count, 0)
    Write-Progress -Activity "Conversion in progress" -Status "$perc% Complete:" -PercentComplete $perc

    #echo ($i.ToString() + ": " + $f.FullName + " -> " + $outfile + " " + [math]::Round($f.Length / 1KB) + " KB")

    # Compress jpg (-qscale:v from 1 to 31, being 1 the highest quality)
    & ffmpeg -i $f.FullName -qscale:v 7 -loglevel error $outfile

    if (-not(Test-Path $outfile)) {
        Write-Error "Error processing $($f.FullName)"
        continue;
    }

    $newLength = (Get-Item $outfile).length
    $ratio = [math]::Round($newLength / $f.Length, 2)
    echo ($f.Name + " " + ([math]::Round($f.Length / 1KB)).ToString() + " KB -> " + ([math]::Round($newLength / 1KB)) + " KB. Ratio: " + $ratio)
    if ($ratio -gt 0.9) {
        Write-Host "Skpping $($f.FullName) for ratio $($ratio)" -ForegroundColor yellow
        continue;
    }

    $savedSpace = $savedSpace + (($f.Length / 1MB) - ($newLength / 1MB))
    $counter = $counter + 1
    #pause

    # Copy metadata
    & exiftool -overwrite_Original -TagsFromFile $f.FullName -All:All $outfile

    # Copy file dates
    (ls $outfile).CreationTime = (ls $f.FullName).CreationTime
    (ls $outfile).LastWriteTime = (ls $f.FullName).LastWriteTime
    (ls $outfile).LastAccessTime = (ls $f.FullName).LastAccessTime

    # Copy file
    robocopy $outDir $f.DirectoryName $f.Name /NDL /NJH /NJS /nc /ns 

    # Delete temp file
    Remove-Item $outfile

    Write-Host "Done ", $f.Name, ". Saved so far: ", ([math]::Round($savedSpace, 2)), " MB in", $counter, "files (", $i, "/", $files.Count, ")"
}

Write-Host ""
Write-Host "Completed! Saved: ", ([math]::Round($savedSpace, 2)), " MB" -ForegroundColor green
Write-Host ""

