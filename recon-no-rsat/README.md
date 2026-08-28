# Recon Without RSAT

**Zero installation required.** All commands use only Microsoft-signed built-in Windows tools.

## When to use this

- You can't install RSAT (locked down)
- You want zero footprint (no new tools, just built-ins)
- The target is locked down but signed tools work

## Files

| File | Uses | Replaces |
|------|------|----------|
| `1_UsersGroups.bat` | `net.exe user /domain`, `net.exe group /domain` | `dsquery.exe user/group` |
| `2_Trusts_DCs.bat` | `nltest.exe` | `dsquery.exe server`, `nltest.exe /domain_trusts` |
| `3_ADCS_Discover.bat` | `certutil.exe`, `powershell -c` (no RSAT) | Limited AD CS discovery |
| `4_HighValue_Recon.bat` | `cmdkey.exe`, `vaultcmd.exe`, `klist.exe`, `netsh.exe` | Mimikatz for ticket + cred harvesting |
| `Run_All_NoRSAT.bat` | Master runner | - |

## Detection

All commands use Microsoft-signed tools doing standard admin queries.

| Tool | Detection |
|------|-----------|
| `net user /domain` | Zero - sysadmins run this daily |
| `nltest.exe` | Zero - basic DC discovery tool |
| `certutil.exe -ADCA` | Zero - native MS discovery |
| `cmdkey.exe /list` | Zero - lists own stored creds |
| `vaultcmd.exe` | Zero - lists own vault |
| `klist.exe tickets` | Zero - Kerberos viewer |
| `powershell -Command "[ADSI]..."` | Zero - builtin .NET access |

## What we lose vs RSAT

| Capability | With RSAT | Without RSAT |
|------------|-----------|--------------|
| All-domain users list | ✅ Full list | ✅ Net user shows only partial |
| Specific user details | ✅ Full attrs (UAC, last logon, etc.) | ❌ Limited |
| SPNs of all users | ✅ dsquery filter | ❌ Need Kerberoast via LDAP |
| All domain computers | ✅ dsquery computer | ⚠️ Limited via net view |
| AD CS template ACL | ✅ dsquery with full attrs | ❌ Limited to certutil -CATemplates |
| Group member details | ✅ dsget group | ⚠️ net group shows less |

## For the things RSAT provides that net doesn't:

Use **PowerShell + ADSI** (built-in, no install):
```powershell
$entry = [ADSI]"LDAP://DC=lioncapital,DC=local"
$searcher = [adsisearcher]"(&(objectCategory=user)(servicePrincipalName=*))"
$searcher.PageSize = 1000
$searcher.FindAll() | ForEach-Object {
    $u = $_.GetDirectoryEntry()
    Write-Host $u.samaccountname " - " $u.servicePrincipalName[0]
}
```

This works on plain Win10 without any installation.

## Run

```cmd
cd C:\path\to\recon-no-rsat
Run_All_NoRSAT.bat
```

Or one by one:
```cmd
Run_All_NoRSAT.bat
1_UsersGroups.bat
2_Trusts_DCs.bat
3_ADCS_Discover.bat
4_HighValue_Recon.bat
```
