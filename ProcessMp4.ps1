$files = Get-ChildItem -Path ./ | where-object {$_.Extension -eq ".mp4" -and $_.length -gt 1MB} | Sort-Object -Property Length
for ($i=0; $i -lt $files.Count; $i++) {
    $f = $files[$i]
    $name = $f.Name;
    Write-Host $f.FullName

    $perc = [math]::Round($i * 100 / $files.Count, 0)
    Write-Progress -Activity "Conversion in progress" -Status "$perc% Complete:" -PercentComplete $perc
    $outFile = "p\$name"

    # Process video
    & ffmpeg -i $f.FullName -c:v libx265 -b:v 3500k $outFile
	
    # Copy metadata
    & exiftool -overwrite_Original -TagsFromFile $f.FullName -All:All $outFile

    # Copy file dates
    (ls $outfile).CreationTime = (ls $f.FullName).CreationTime
    (ls $outfile).LastWriteTime = (ls $f.FullName).LastWriteTime
    (ls $outfile).LastAccessTime = (ls $f.FullName).LastAccessTime
}
