# ad_recon_adsi.ps1
# Pure built-in AD enumeration via [adsisearcher] - no RSAT, no dsquery
# Run with: powershell -ExecutionPolicy Bypass -File ad_recon_adsi.ps1
# Output: $env:TEMP\ad_recon_adsi.log

$ErrorActionPreference = "Continue"
$DOMAIN = "lioncapital.local"
$OUTFILE = "$env:TEMP\ad_recon_adsi.log"

$log = @()
$log += "=" * 60
$log += "AD RECON (PowerShell ADSI, no RSAT required)"
$log += "Time: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
$log += "User: $env:USERDOMAIN\$env:USERNAME"
$log += "=" * 60
$log += ""

# ---------------------------------------------------------------
# 1. Domain info via [System.DirectoryServices.ActiveDirectory]
# ---------------------------------------------------------------
$log += ""
$log += "=== [1] DOMAIN INFO ==="
try {
    $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $log += "Domain Name:   $($dom.Name)"
    $log += "Forest Name:   $($dom.Forest.Name)"
    $log += "PDC Owner:     $($dom.PdcRoleOwner)"
    $log += "RID Master:    $($dom.RidRoleOwner)"
    $log += "Infra Master:  $($dom.InfrastructureRoleOwner)"
    $log += "Domain Mode:   $($dom.DomainMode)"
    $log += "Forest Mode:   $($dom.Forest.ForestMode)"
    $log += "Domain GUID:   $($dom.Forest.RootDomain.DomainGuid)"
    $log += "Domain SID:    $($dom.DomainSid)"
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 2. Forest info
# ---------------------------------------------------------------
$log += ""
$log += "=== [2] FOREST INFO ==="
try {
    $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    $log += "Forest Root:   $($forest.RootDomain)"
    $log += "Forest Schema Master: $($forest.SchemaRoleOwner)"
    $log += "Forest Naming Master: $($forest.NamingRoleOwner)"
    $log += "Forest Domains:"
    foreach ($d in $forest.Domains) {
        $log += "  - $($d.Name) ($($d.DomainMode))"
    }
    $log += "Global Catalogs:"
    foreach ($gc in $forest.FindAllGlobalCatalogs() | Select-Object -First 10) {
        $log += "  - $($gc.Name)"
    }
    $log += "Sites:"
    foreach ($s in $forest.Sites) {
        $log += "  - $($s.Name)"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 3. Domain Controllers
# ---------------------------------------------------------------
$log += ""
$log += "=== [3] DOMAIN CONTROLLERS ==="
$searcher = [adsisearcher]"(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))"
$searcher.PageSize = 1000
try {
    foreach ($r in $searcher.FindAll()) {
        $name = $r.Properties["name"][0]
        $os   = $r.Properties["operatingsystem"][0]
        $dns  = $r.Properties["dnshostname"][0]
        $log += "  $name | $os | $dns"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 4. All domain users (limited fields)
# ---------------------------------------------------------------
$log += ""
$log += "=== [4] ALL DOMAIN USERS (count only, with samaccountname) ==="
$searcher = [adsisearcher]"(&(objectCategory=user)(objectClass=user))"
$searcher.PageSize = 1000
$searcher.SizeLimit = 0
try {
    $users = $searcher.FindAll()
    $log += "Total user objects: $($users.Count)"
    foreach ($u in $users | Sort-Object { $_.Properties["samaccountname"][0] }) {
        $name = $u.Properties["samaccountname"][0]
        $log += "  $name"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 5. SPN users (Kerberoastable)
# ---------------------------------------------------------------
$log += ""
$log += "=== [5] USERS WITH SPN (Kerberoastable) ==="
$searcher = [adsisearcher]"(&(objectCategory=user)(objectClass=user)(servicePrincipalName=*))"
$searcher.PageSize = 1000
$searcher.SizeLimit = 0
try {
    $res = $searcher.FindAll()
    $log += "Total SPN accounts: $($res.Count)"
    foreach ($r in $res) {
        $u = $r.GetDirectoryEntry()
        $name = $u.samaccountname
        $spn  = $u.servicePrincipalName -join ","
        $log += "  $name -> $spn"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 6. AS-REP Roastable (DONT_REQ_PREAUTH = 0x400000 = 4194304)
# ---------------------------------------------------------------
$log += ""
$log += "=== [6] USERS WITH NO-PREAUTH (AS-REP Roastable) ==="
$searcher = [adsisearcher]"(&(objectCategory=user)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))"
$searcher.PageSize = 1000
try {
    $res = $searcher.FindAll()
    $log += "Total AS-REP accounts: $($res.Count)"
    foreach ($r in $res) {
        $log += "  $($r.Properties['samaccountname'][0])"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 7. Password never expires (0x10000 = 65536)
# ---------------------------------------------------------------
$log += ""
$log += "=== [7] USERS WITH PASSWORD NEVER EXPIRES ==="
$searcher = [adsisearcher]"(&(objectCategory=user)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))"
$searcher.PageSize = 1000
try {
    $res = $searcher.FindAll()
    $log += "Total never-expires: $($res.Count)"
    foreach ($r in $res) {
        $log += "  $($r.Properties['samaccountname'][0])"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 8. All domain groups
# ---------------------------------------------------------------
$log += ""
$log += "=== [8] ALL DOMAIN GROUPS ==="
$searcher = [adsisearcher]"(&(objectCategory=group))"
$searcher.PageSize = 1000
try {
    $res = $searcher.FindAll()
    $log += "Total groups: $($res.Count)"
    foreach ($r in $res | Sort-Object { $_.Properties["samaccountname"][0] }) {
        $name = $r.Properties["samaccountname"][0]
        $log += "  $name"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 9. Privileged groups - member listings
# ---------------------------------------------------------------
$log += ""
$log += "=== [9] PRIVILEGED GROUP MEMBERSHIPS ==="
$privGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Account Operators",
    "Backup Operators",
    "Server Operators",
    "Print Operators",
    "Cert Publishers",
    "Group Policy Creator Owners",
    "DnsAdmins",
    "LAPS Operators"
)
foreach ($g in $privGroups) {
    $searcher = [adsisearcher]"(memberOf=CN=$g,CN=Users,DC=lioncapital,DC=local)"
    $searcher.PageSize = 1000
    try {
        $res = $searcher.FindAll()
        $log += ""
        $log += "  --- $g ($($res.Count) members) ---"
        foreach ($r in $res) {
            $u = $r.GetDirectoryEntry()
            $log += "    $($u.samaccountname)"
        }
    } catch {
        $log += "  --- $g (query failed: $($_.Exception.Message)) ---"
    }
}

# ---------------------------------------------------------------
# 10. All domain computers
# ---------------------------------------------------------------
$log += ""
$log += "=== [10] ALL DOMAIN COMPUTERS ==="
$searcher = [adsisearcher]"(&(objectCategory=computer))"
$searcher.PageSize = 1000
try {
    $res = $searcher.FindAll()
    $log += "Total computers: $($res.Count)"
    foreach ($r in $res | Sort-Object { $_.Properties["name"][0] }) {
        $name = $r.Properties["name"][0]
        $os   = $r.Properties["operatingsystem"][0] -join ","
        $log += "  $name | $os"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 11. OUs
# ---------------------------------------------------------------
$log += ""
$log += "=== [11] ALL ORGANIZATIONAL UNITS ==="
$searcher = [adsisearcher]"(&(objectCategory=organizationalUnit))"
$searcher.PageSize = 1000
try {
    $res = $searcher.FindAll()
    $log += "Total OUs: $($res.Count)"
    foreach ($r in $res | Sort-Object { $_.Properties["name"][0] }) {
        $name = $r.Properties["name"][0]
        $path = $r.Properties["distinguishedname"][0]
        $log += "  $name -> $path"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 12. AD CS - CAs via LDAP
# ---------------------------------------------------------------
$log += ""
$log += "=== [12] AD CS - ENTERPRISE CAs ==="
$searcher = [adsisearcher]"(&(objectCategory=pKIEnrollmentService))"
$searcher.PageSize = 100
try {
    $res = $searcher.FindAll()
    $log += "Total CAs: $($res.Count)"
    foreach ($r in $res) {
        $name = $r.Properties["name"][0]
        $dns  = $r.Properties["dnshostname"][0]
        $log += "  $name @ $dns"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 13. AD CS - Certificate Templates via LDAP
# ---------------------------------------------------------------
$log += ""
$log += "=== [13] AD CS - CERTIFICATE TEMPLATES ==="
$searcher = [adsisearcher]"(&(objectClass=pKICertificateTemplate))"
$searcher.PageSize = 1000
try {
    $res = $searcher.FindAll()
    $log += "Total templates: $($res.Count)"
    foreach ($r in $res | Sort-Object { $_.Properties["name"][0] }) {
        $name = $r.Properties["name"][0]
        $displayName = $r.Properties["displayName"][0]
        $log += "  $name (display: $displayName)"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 14. AD CS - ESC1 candidates (ENROLLEE_SUPPLIES_SUBJECT)
# ---------------------------------------------------------------
$log += ""
$log += "=== [14] AD CS - ESC1 CANDIDATES (msPKI-Certificate-Name-Flag bit 0 set) ==="
$searcher = [adsisearcher]"(&(objectClass=pKICertificateTemplate)(msPKI-Certificate-Name-Flag:1.2.840.113556.1.4.803:=1))"
$searcher.PageSize = 1000
try {
    $res = $searcher.FindAll()
    $log += "Total ESC1 candidates: $($res.Count)"
    foreach ($r in $res) {
        $name = $r.Properties["name"][0]
        $displayName = $r.Properties["displayName"][0]
        $log += "  [ESC1] $name (display: $displayName)"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 15. AD CS - ESC6 candidates (CA flags with EDITF_ATTRIBUTESUBJECTALTNAME2)
# ---------------------------------------------------------------
$log += ""
$log += "=== [15] AD CS - ESC6 CANDIDATES (CA flag 0x80000) ==="
$searcher = [adsisearcher]"(&(objectCategory=pKIEnrollmentService)(flags:1.2.840.113556.1.4.803:=524288))"
$searcher.PageSize = 100
try {
    $res = $searcher.FindAll()
    $log += "Total ESC6 candidates: $($res.Count)"
    foreach ($r in $res) {
        $name = $r.Properties["name"][0]
        $log += "  [ESC6] $name"
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 16. AD CS - Vulnerable template ACLs (Domain Users can enroll)
# ---------------------------------------------------------------
$log += ""
$log += "=== [16] AD CS - DOMAIN-USERS-ENROLL TEMPLATES ==="
# Look at template security descriptor (nTSecurityDescriptor attribute)
$searcher = [adsisearcher]"(&(objectClass=pKICertificateTemplate))"
$searcher.PageSize = 1000
try {
    foreach ($t in $searcher.FindAll()) {
        $name = $t.Properties["name"][0]
        $sd = $t.Properties["ntsecuritydescriptor"]
        if ($sd) {
            $log += "  $name - has SD (analyzing ACEs requires Python)"
        }
    }
} catch {
    $log += "FAILED: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# Write output
# ---------------------------------------------------------------
$log -join "`n" | Out-File -FilePath $OUTFILE -Encoding utf8

Write-Host ""
Write-Host "[+] Output written to: $OUTFILE" -ForegroundColor Green
Write-Host ""
Write-Host "=== QUICK SUMMARY ==="
Write-Host $log[0..50] -Separator "`n"
