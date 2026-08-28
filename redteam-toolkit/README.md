# Red Team Toolkit - Sunz Assessment

Three pillars covering lateral movement, AD CS attack, and detection evasion.

## Pillar 1: Lateral Movement

Files in `Pillar1_Lateral/`:
- `Signed_PassTheHash.bat` - Pass-the-hash via mimikatz
- `Signed_WinRM.ps1` - WinRM abuse with PowerShell
- `Signed_RDP.bat` - RDP lateral movement
- `PTK_PTH_Notes.md` - Reference for hash/ticket attacks

## Pillar 2: AD CS Attack

Files in `Pillar2_ADCS/`:
- `ADCS_Certipy_Runbook.md` - Full attack chain via Certipy
- `CA_Discovery_Bat.bat` - Find CAs via signed certutil + dsquery

Use Certipy from this Linux box to confirm ESC1 / ESC6 etc. Then exploit.

## Pillar 3: Detection Evasion

Files in `Pillar3_Evasion/`:
- `LOLBin_Toolkit.bat` - Signed-binary abuse catalog
- `ULP_Bypass.cs` - UAC bypass methods (compile + run on target)
- `AMSI_Bypass_Notes.md` - AMSI/ETW bypass for offensive ops
- `Persistence_Methods.md` - Documented persistence techniques

## Recommended Attack Flow

```
1. Run stealth-attack-signed-v2/Run_All.bat (signed recon, zero detection)
   - Output: kerb_*.log, adcs_*.log, ad_*.log
   
2. From the AD recon, identify:
   - Service accounts with SPNs (Kerberoast targets)
   - Domain controllers and CA servers
   - Domain admin / enterprise admin group members
   
3. Run Pillar2_ADCS/CA_Discovery_Bat.bat to find ESC vulnerabilities
   - If ESC1 or ESC6 found → forge admin cert → game over
   
4. After one set of admin creds:
   - Use Pillar1_Lateral/Signed_PassTheHash.bat for lateral movement
   - Run Pillar3_Evasion/ for stealth execution on each new host
   
5. Maintain persistence with Pillar3_Evasion/Persistence_Methods.md

## Engagement Considerations

- Always log what you do (command + timestamp + tool used)
- Track which techniques got caught by blue team
- Report findings in red team deliverable format
- Don't break production systems during testing
- Coordinate with blue team before destructive actions
