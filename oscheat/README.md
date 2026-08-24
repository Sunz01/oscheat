# OSCheat - Comprehensive Windows Enumerator

WinPEAS-style consolidated enumeration tool for authorized internal penetration testing and OSCP/OSCE-style lab work.

**Author:** Sunz + Flint (Flint Flich 🔥)
**Use only on systems you own or have explicit written authorization to test.**

## 🚀 Quick Start (pick what works for you)

| Format | File | When to use |
|--------|------|-------------|
| **`oscheat.bat`** | CMD launcher | ⭐ **Use this first.** Double-click to run. Streams the .ps1 to PowerShell with full bypass — works around execution policy. |
| **`oscheat.ps1`** | PowerShell | Native Windows, best output. Run with `powershell -ExecutionPolicy Bypass -File oscheat.ps1` |
| **`oscheat.py`** | Pure Python | Works without PowerShell. Use if PowerShell is locked down. |
| **`oscheat.exe`** | Standalone binary | Build on Windows with `pip install pyinstaller && python build_exe.py`. Use when nothing else works. |

## 📦 What's in here

```
oscheat/
├── oscheat.ps1          # PowerShell version (most comprehensive)
├── oscheat.bat          # Launch that bypasses execution policy  
├── oscheat.py           # Pure Python version (no PowerShell needed)
├── build_exe.py         # PyInstaller builder (run on Windows)
└── README.md            # This file
```

## 🎯 Usage Recipes

### Recipe 1: BAT launcher (recommended first try)
```cmd
:: Place oscheat.bat + oscheat.ps1 in same folder
:: Double-click oscheat.bat OR run from cmd:
.\oscheat.bat
```
The .bat streams oscheat.ps1 to PowerShell via stdin — this **bypasses execution policy blocks**.

### Recipe 2: Direct PowerShell
```powershell
powershell -ExecutionPolicy Bypass -NoProfile -File .\oscheat.ps1
powershell -ExecutionPolicy Bypass -NoProfile -File .\oscheat.ps1 -Quiet
```

### Recipe 3: Pure Python (no PowerShell at all)
```cmd
:: Requires Python 3.x installed on target
python oscheat.py
python oscheat.py --quiet
```

### Recipe 4: Standalone .exe
```cmd
:: Build once (on any Windows box with Python):
pip install pyinstaller
python build_exe.py

:: Copy oscheat.exe to target, run:
oscheat.exe
oscheat.exe --quiet
```

## 🎯 What it checks (12 sections)

1. **System Info** — OS version, hotfixes, integrity level
2. **Users & Groups** — `whoami /all` with auto-highlight of dangerous privileges
3. **Network** — adapters, ports, ARP, DNS, shares
4. **Processes & Services** — process tree, unquoted service paths
5. **Installed Software** — highlights interesting targets
6. **Scheduled Tasks** — flags privileged tasks with stored creds
7. **Autostart** — registry Run keys + Startup folders
8. **Credentials & Secrets** — cmdkey, AutoLogon, WiFi passwords, GPP cpassword, SAM backups
9. **Security Policy & UAC** — AlwaysInstallElevated, UAC level, WDigest
10. **Filesystem** — heuristic search for password files

## 🛡️ Safety boundaries

This tool is for authorized testing only. By design it does NOT include:
- ❌ Active EDR evasion logic
- ❌ AMSI bypass / logging evasion
- ❌ Process injection helpers
- ❌ Built-in Mimikatz (download separately)
- ❌ Script obfuscation

Use standalone tools (SharpHound, mimikatz, Rubeus, etc.) for those — separation of concerns is the right architecture.

## 📚 OSCP study tip

Run the script on lab boxes (HTB, TryHackMe, PWK labs) and read the comments inline. The script is heavily documented with `<# #>` blocks explaining WHY each check matters. Understanding the checks beats memorizing output — that's what passes OSCP.

## 📋 Output

Every run drops reports in `%TEMP%\oscheat_<timestamp>\` (or `/tmp/oscheat_*` on Linux). Final summary always prints findings even if you cancel mid-run.

## 🤝 Contributing

This is a study tool — fork it, add your own checks, share with your team. Just remember the use case: **authorized** testing only.

---

**Quick escalation lookup (after running OSCheat):**

| Finding | Path |
|---------|------|
| AlwaysInstallElevated | `msfvenom -p windows/adduser ... -f msi > evil.msi` |
| SeImpersonate | `JuicyPotato.exe -l 9999 -p c:\windows\system32\cmd.exe -t *` (or PrintSpoofer on Win10+) |
| Unquoted service path | Place `Program.exe` in writable parent dir |
| WDigest | Mimikatz `sekurlsa::wdigest` |
| GPP cpassword | `gpp-decrypt <cpassword>` (Python one-liner) |
| cmdkey cred | `runas /savecred /user:admin "cmd /c whoami"` |
