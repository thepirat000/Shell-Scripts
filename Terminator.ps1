# Will immediately terminate all the non-essential processes

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;

public static class WinProcess
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool IsProcessCritical(IntPtr hProcess, ref bool Critical);

    public static List<Process> GetNonCritical()
    {
        return Process.GetProcesses()
            .Where(p =>
            {
                try
                {
                    if (p.HasExited)
                    {
                        return false;
                    }
                    bool isCritical = false;
                    var result = WinProcess.IsProcessCritical(p.Handle, ref isCritical);
                    return !result || !isCritical;
                }
                catch
                {
                    return false;
                }
            })
            .OrderBy(p => p.ProcessName)
            .ToList();
    }
};
"@

$doNotKill = "conhost", "svchost", "dwm", "cmd", "explorer", "powershell", "wininit", "winlogon", "fontdrvhost", "lsass", "Bootcamp", "BootCampService", "SystemSettings", "HxTsr", "HxCalendarAppImm", "LockApp", "LogiOptions", "LogiOptionsMgr", "OpenConsole"
ForEach ($p in [WinProcess]::GetNonCritical())
{
    if (-not $doNotKill.Contains($p.Name))
    {
        Write-Host $p.Name, $p.Handle, $letter
        Stop-Process -Id $p.Id -Force
    }
}
