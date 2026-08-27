# StealthAttack Pack

Mirror of `StealthEnum.cs` style — single-file C#, compiles with built-in `csc.exe`, no third-party libs, runs from `%TEMP%`.

Designed to be **stealthy**:
- Compiled binaries dropped to `%TEMP%` (not in any tracked folder)
- All output to `.log` files in `%TEMP%`
- No `cmdkey /list` or hardware-changing calls
- Only LDAP queries (no raw SMB/WMI process spawns beyond lightweight `Process`)
- Doesn't touch filesystem outside `%TEMP%`

## Files

| File | Purpose |
|------|---------|
| `StealthKerb.cs` | Kerberoast + AS-REP roast enumeration |
| `StealthADCS.cs` | AD CS (Certificate Services) vulnerability scan |
| `StealthSMB.cs` | Full AD dump (computers, users, groups, trusts) |
| `Run_All.bat` | Single bat that compiles + runs all three |

## Compile + Run

```cmd
:: Single command (same as StealthEnum pattern):
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:%TEMP%\r.exe /r:System.DirectoryServices.dll StealthKerb.cs
%TEMP%\r.exe > %TEMP%\kerb.log 2>&1
type %TEMP%\kerb.log

:: Or one-shot:
Run_All.bat
```

## What Each Script Does

### `StealthKerb.cs`
- ✅ Lists all users with SPNs (Kerberoastable service accounts)
- ✅ Lists AS-REP roastable users (no preauth flag set)
- ✅ Lists users with non-expiring passwords
- ✅ Runs `net user /domain` for human-readable user list

### `StealthADCS.cs`
- ✅ Finds all CAs (Certificate Authorities) and their templates
- ✅ Flags **ESC1** templates (ENROLLEE_SUPPLIES_SUBJECT + no EKU + no RA sig)
- ✅ Checks CA flags for **ESC6** (EDITF_ATTRIBUTESUBJECTALTNAME2 = `0x00080000`)
- ✅ Shows flag bits for each CA

### `StealthSMB.cs` 
- ✅ All computers with OS (and DC flag)
- ✅ All users (with descriptions) — first 100 + any with admin/svc/backup in name
- ✅ All groups (with member counts)
- ✅ All domain trusts (inbound / outbound / bidirectional)

## Detection

- **csc.exe compile**: triggers Sysmon EID 1, but is allowed in most environments
- **LDAP queries from user context**: legitimate, normal AD traffic
- **Memory-only**: each script can be compiled and run from `\\<server>\NETLOGON\` or a temp folder, deleted after
- **No suspicious outbound traffic** — only AD-bound LDAP/SMB/RPC

## CSV/SPN Harvest

```cmd
:: Extract just SPNs from kerb.log:
findstr "SPN" %TEMP%\kerb.log
findstr "NO-PREAUTH" %TEMP%\kerb.log
findstr "ESC1 VULNERABLE" %TEMP%\adcs.log
findstr "EDITF_ATTRIBUTESUBJECTALTNAME2" %TEMP%\adcs.log
```

## Next steps after recon

1. **If ESC1 found** → use `certipy req` (separate tool, requires download) or write a custom C# CertEnroll client
2. **If SPNs cracked** → use that account for lateral movement
3. **If no-preauth accounts found** → AS-REP roast their hashes and crack offline
