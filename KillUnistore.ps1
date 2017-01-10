#KILL UniStore Microsoft "virus"
$id = Get-WmiObject -Class Win32_Service -Filter "Name LIKE '%Unistore%'" | Select-Object -ExpandProperty ProcessId

if ($id -gt 0)
{
    Write-Host "To kill PID", $id
    Stop-Process $id -Force
}
