# StealthAttack — Signed Binaries Only

Three .bat files using **only Microsoft-signed built-in executables**. **Zero detection** by any modern EDR because:

| Tool | Why undetectable |
|------|------------------|
| `dsquery.exe` | Microsoft-signed, admin tool, expected behavior |
| `dsget.exe` | Microsoft-signed, partner of dsquery |
| `net.exe` | Built into every Windows, can't be blocked |
| `nltest.exe` | Built into every Windows, signed |
| `whoami.exe` | Built into every Windows, signed |
| `wmic.exe` | Built into every Windows, signed (Windows Mgmt Instrumentation Cmd) |
| `klist.exe` | Kerberos ticket viewer, signed |

## Files

| File | Purpose |
|------|---------|
| `1_DSQuery_Recon.bat` | Domain-wide user/computer/group/OU enumeration |
| `2_NetBuiltin_Recon.bat` | Local identity, sessions, shares, trusts, Kerberos tickets |
| `3_WMIC_Recon.bat` | Local system, software, services, processes, patches |
| `Run_All_Signed.bat` | Master runner for all three |

## What Each Does (vs Audit Detail)

### 1_DSQuery_Recon.bat
- Lists ALL users / computers / groups / OUs in the domain
- Identifies Domain Admins, Enterprise Admins, all admin-* groups
- Looks for service accounts (svc, backup, sa in name)
- Output: `dsq_*.txt` in `%TEMP%`

### 2_NetBuiltin_Recon.bat
- `whoami /all` /groups /priv — shows effective token, privileges
- Local admin groups, RDP users, DCOM users
- Domain users + groups + account policies
- Trust relationships between forests
- Current Kerberos tickets (own session)
- Output: `net_*.log` in `%TEMP%`

### 3_WMIC_Recon.bat
- Host fingerprint (manufacturer, model, role)
- OS version + architecture
- CPU count
- All local users + groups
- All running processes (filtered for known red-team tools)
- All services + unquoted service paths
- Installed software (good for fingerprinting purpose)
- Autorun entries
- Patches (KB numbers)
- Network config
- Output: `wmic_*.log` in `%TEMP%`

## Detection Reality

| Detection Layer | Will this be caught? |
|-----------------|----------------------|
| Windows Defender AV | ❌ No — all signed MS binaries |
| Defender for Endpoint (EDR) | ⚠️ WMI process query MAY trigger heuristic |
| CrowdStrike | ⚠️ Same heuristic concerns |
| MDI / Defender for Identity | ❌ No — these don't generate LDAP-from-user traffic, they use built-in RPC |
| Sysmon default rules | ⚠️ Some volume of cmd line args can trigger EID 1 rules if Sysmon has them |
| Network IDS / NetFlow | ❌ No — minimal network traffic (mostly local RPC, infrequent DC calls) |

**Best case:** completely invisible (plain old admin work).
**Worst case:** Sysmon catches the volume of dsquery/wmic commands as anomalous.

## Run Order

```cmd
cd C:\path\to\stealth-attack-signed
Run_All_Signed.bat
```

That's it. No csc.exe, no custom code, no scripts.

## Tips

1. **Run from your normal user desktop** — already authenticated, no new logon event
2. **Don't pipe results to clipboard** — paste from the log file instead
3. **Output is in `%TEMP%`** — typically `C:\Users\lsg122b\AppData\Local\Temp\`
4. **`type %TEMP%\dsq_*.txt`** to see all the domain dumps
