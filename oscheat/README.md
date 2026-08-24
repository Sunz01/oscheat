# OSCheat - Comprehensive Windows Enumerator

WinPEAS-style consolidated enumeration tool for **authorized** internal penetration testing and OSCP/OSCE-style lab work.

**Author:** Sunz + Flint (Flint Flich 🔥)
**Use only on systems you own or have explicit written authorization to test.**

## 🚀 Quick start

| Order | Try this | When |
|-------|----------|------|
| 1️⃣ | **`python oscheat.py`** | Python is installed and accessible from PATH |
| 2️⃣ | **`oscheat.ps1` + `powershell -ExecutionPolicy Bypass -File oscheat.ps1`** | PowerShell execution policy is bypassable |
| 3️⃣ | **`run_keep_open.bat`** | CMD works but PS script execution has issues |
| 4️⃣ | **`build_cs.bat`** (then run `oscheat.exe`) | Everything above is blocked — csc.exe ships with every Windows install |
| 5️⃣ | **`CHECK_TOOLS.bat`** | See what tools are actually available on this box |

**Don't know what works on your box?** Run `CHECK_TOOLS.bat` first — it scans for python, node, csc.exe, git, etc. and recommends the best path.

## 📦 Files included

```
oscheat/
├── oscheat.cs            # Pure C# source (compiles to .exe with csc.exe)
├── oscheat.ps1           # PowerShell version (most comprehensive)
├── oscheat.py            # Pure Python (no PowerShell needed)
├── oscheat.bat           # CMD launcher for oscheat.ps1
├── run_keep_open.bat     # Bulletproof wrapper around oscheat.bat
├── build_cs.bat          # Compiles oscheat.cs using built-in csc.exe
├── build_exe.py          # PyInstaller builder for oscheat.py
├── CHECK_TOOLS.bat       # Diagnostics: scans what tools are available
└── README.md             # This file
```

## 🔧 Why 5 versions?

Different Windows boxes have different restrictions. The matrix:

| Environment | What works |
|-------------|-----------|
| Default Win10+ dev box | `oscheat.ps1` via direct `-File` |
| Corporate with restricted PS | `oscheat.bat` or `run_keep_open.bat` |
| Locked down, Python allowed | `python oscheat.py` |
| Locked down, Python blocked but .NET available | `build_cs.bat` → `oscheat.exe` |
| Maximum lockdown | Use pre-built `oscheat.exe` (compile on an unrestricted box first) |

The C# version is special: **csc.exe is part of .NET Framework, which is built into every Windows install since XP**. No install needed, no admin needed. Compile a fresh .exe anywhere.

## 🎯 What it checks (10 sections)

1. **System Info** — OS version, hotfixes, integrity level
2. **Users & Groups** — `whoami /all` with auto-highlight of dangerous privileges
3. **Network** — adapters, ports, ARP, DNS, shares
4. **Processes & Services** — tasklist, sc query, **unquoted service paths**
5. **Installed Software** — highlights interesting targets (Putty, WinSCP, AV products, etc.)
6. **Scheduled Tasks** — flags privileged tasks
7. **Autostart** — registry Run keys
8. **Credentials & Secrets** — cmdkey, **AutoLogon password in registry**, **WiFi passwords via netsh**, GPP cpassword
9. **Security Policy & UAC** — **AlwaysInstallElevated**, UAC level, **WDigest**
10. **Filesystem** — heuristic search for password/credential files

## 💻 Recipe 1: BAT launcher

```cmd
cd C:\Users\yourname\Downloads
.\oscheat.bat
```

Or `run_keep_open.bat` for a window that stays open even if errors occur.

## 💻 Recipe 2: Direct PowerShell

```powershell
powershell -ExecutionPolicy Bypass -NoProfile -File .\oscheat.ps1
powershell -ExecutionPolicy Bypass -NoProfile -File .\oscheat.ps1 -Quiet
```

## 💻 Recipe 3: Pure Python

```cmd
python oscheat.py
python oscheat.py --quiet
```

## 💻 Recipe 4: Built-in .exe (NO install needed)

```cmd
:: Run this ONCE on the target box, with oscheat.cs in same folder:
build_cs.bat

:: Produces: oscheat.exe (single executable)
:: Then run:
oscheat.exe
```

`build_cs.bat` uses `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe` which **already exists on every Windows machine**. No install, no admin, no nothing.

## 🛡️ Safety boundaries

By design, OSCheat does NOT include:
- ❌ Active EDR evasion logic
- ❌ AMSI bypass / logging evasion
- ❌ Process injection helpers
- ❌ Built-in Mimikatz
- ❌ Script obfuscation

Use standalone tools (SharpHound, mimikatz, Rubeus) for those.

## 📚 OSCP study tip

Run on lab boxes (HTB, TryHackMe, PWK labs) and read the inline comments. The C# and PowerShell versions are heavily documented — understanding what each check does beats memorizing output.

## 📋 Output

Reports saved to `%TEMP%\oscheat_<timestamp>\`. Final summary always prints findings even if you cancel mid-run.

## ⚡ Quick escalation lookup

| Finding | Path |
|---------|------|
| AlwaysInstallElevated | `msfvenom -p windows/adduser ... -f msi > evil.msi && msiexec /quiet /qn /i evil.msi` |
| SeImpersonate | `JuicyPotato.exe -l 9999 -p c:\windows\system32\cmd.exe` / `PrintSpoofer64.exe -i -c cmd` |
| Unquoted service path | Drop `Program.exe` in writable parent dir |
| WDigest | Mimikatz from your box: `sekurlsa::wdigest` |
| GPP cpassword | `gpp-decrypt <cpassword>` (Python one-liner) |
| cmdkey cred | `runas /savecred /user:admin "cmd /c whoami"` |

---

**Never run this on a system you don't have written authorization to test.**
