// ===============================================
// run_via_js.js - AD recon via JScript + ADO
// Most stealth: no PS1, no VBS file extension
// Output: %TEMP%\ad_recon_js.log
// Run: cscript.exe //NoLogo run_via_js.js
// ===============================================
var fso = new ActiveXObject("Scripting.FileSystemObject");
var shell = new ActiveXObject("WScript.Shell");
var tempDir = shell.ExpandEnvironmentStrings("%TEMP%");
var logFile = tempDir + "\\ad_recon_js.log";

var logFileStream = fso.CreateTextFile(logFile, true);

function log(s) {
    WScript.Echo(s);
    logFileStream.WriteLine(s);
}

function getDomain() {
    var rootDSE = new ActiveXObject("ADSystemInfo").GetAnyDCName();
    var x = rootDSE;
    var rootObj = GetObject("LDAP://RootDSE");
    var dom = rootObj.Get("defaultNamingContext");
    return dom;
}

function adodbQuery(query, fields) {
    var conn = new ActiveXObject("ADODB.Connection");
    conn.Provider = "ADsDSOObject";
    conn.Open("Active Directory Provider");
    var rs = conn.Execute(query);
    var results = [];
    while (!rs.EOF) {
        var row = {};
        for (var i = 0; i < fields.length; i++) {
            try {
                row[fields[i]] = rs.Fields(fields[i]).Value;
            } catch(e) {
                row[fields[i]] = null;
            }
        }
        results.push(row);
        rs.MoveNext();
    }
    rs.Close();
    conn.Close();
    return results;
}

log("=== AD RECON via JScript (no PS1) ===");
log("Time: " + new Date().toString());
log("");

var dom = getDomain();
log("[1] Domain: " + dom);

log("");
log("[2] Kerberoastable users (SPN > 0)");
var users = adodbQuery(
    "<LDAP://" + dom + ">;(objectCategory=user)(servicePrincipalName=*);samaccountname,servicePrincipalName;SubTree",
    ["samaccountname", "servicePrincipalName"]
);
for (var i = 0; i < users.length; i++) {
    var spn = users[i].servicePrincipalName;
    var spnStr = (spn ? spn.toString() : "");
    log("  [KERBEROAST] " + users[i].samaccountname + " -> " + spnStr);
}
log("Total Kerberoastable: " + users.length);

log("");
log("[3] AS-REP Roastable (DONT_REQ_PREAUTH)");
var asrep = adodbQuery(
    "<LDAP://" + dom + ">;(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304);samaccountname;SubTree",
    ["samaccountname"]
);
for (var i = 0; i < asrep.length; i++) {
    log("  [AS-REP] " + asrep[i].samaccountname);
}
log("Total AS-REP: " + asrep.length);

log("");
log("[4] Never-expiring password users");
var never = adodbQuery(
    "<LDAP://" + dom + ">;(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=65536);samaccountname;SubTree",
    ["samaccountname"]
);
for (var i = 0; i < never.length; i++) {
    log("  [NEVER-EXPIRE] " + never[i].samaccountname);
}
log("Total never-expire: " + never.length);

log("");
log("[5] Privileged group memberships");
var privGroups = ["Domain Admins", "Enterprise Admins", "Schema Admins", "Account Operators", "Backup Operators", "Cert Publishers", "DnsAdmins"];
for (var g = 0; g < privGroups.length; g++) {
    log("");
    log("  --- " + privGroups[g] + " ---");
    var members = adodbQuery(
        "<LDAP://" + dom + ">;(memberOf=CN=" + privGroups[g] + ",CN=Users," + dom + ");samaccountname;SubTree",
        ["samaccountname"]
    );
    for (var i = 0; i < members.length; i++) {
        log("    " + members[i].samaccountname);
    }
    log("  Count: " + members.length);
}

log("");
log("[6] All domain computers");
var comps = adodbQuery(
    "<LDAP://" + dom + ">;(objectCategory=computer);name,operatingsystem;SubTree",
    ["name", "operatingsystem"]
);
for (var i = 0; i < comps.length; i++) {
    log("  " + comps[i].name + " | " + comps[i].operatingsystem);
}
log("Total computers: " + comps.length);

log("");
log("[7] AD CS CAs");
var cas = adodbQuery(
    "<LDAP://CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration," + dom + ">;(objectCategory=pKIEnrollmentService);name,dnsHostName;SubTree",
    ["name", "dnsHostName"]
);
for (var i = 0; i < cas.length; i++) {
    log("  CA: " + cas[i].name + " @ " + cas[i].dnsHostName);
}

log("");
log("[8] Certificate Templates");
var templates = adodbQuery(
    "<LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration," + dom + ">;(objectClass=pKICertificateTemplate);name,displayName,msPKI-Certificate-Name-Flag,flags;SubTree",
    ["name", "displayName", "msPKI-Certificate-Name-Flag", "flags"]
);
for (var i = 0; i < templates.length; i++) {
    var t = templates[i];
    var nameFlag = (t["msPKI-Certificate-Name-Flag"] ? t["msPKI-Certificate-Name-Flag"] : 0);
    var flags = (t.flags ? t.flags : 0);
    var esc1 = (nameFlag & 1) ? "[ESC1] " : "";
    log("  " + esc1 + t.name + " (display: " + t.displayName + ")");
}
log("Total templates: " + templates.length);

log("");
log("=== DONE ===");
log("Log saved to: " + logFile);

logFileStream.Close();
WScript.Echo("Press Enter to exit...");
WScript.StdIn.ReadLine();
