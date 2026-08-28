@echo off
setlocal enabledelayedexpansion
REM ============================================
REM  2_ADCS_Recon.bat - AD CS (Active Directory Certificate Services) enumeration
REM  ALL SIGNED MS BINARIES: certutil.exe  dsquery.exe  findstr.exe  type
REM  Replaces custom C# LDAP code with Microsoft-signed binaries.
REM  Output: %TEMP%\adcs_*.log
REM ============================================

set "OUT=%TEMP%"
set "DOM=lioncapital"

echo.
echo === AD CS SERVER LOCATION (auto-discovery) ===
certutil.exe -ADCA > "%OUT%\adcs_caservers.log" 2>&1
type "%OUT%\adcs_caservers.log"

echo.
echo === AD CS TEMPLATE LIST ===
certutil.exe -CATemplates > "%OUT%\adcs_templates.log" 2>&1
type "%OUT%\adcs_templates.log"

echo.
echo === ALL CA CERTIFICATES IN STORE ===
certutil.exe -CAStore > "%OUT%\adcs_castore.log" 2>&1

echo.
echo === ENTERPRISE CA OBJECT (via LDAP, signed dsquery) ===
dsquery.exe * "CN=Configuration,DC=%DOM%,DC=local" -filter "(objectClass=pKIEnrollmentService)" -attr cn dnsHostname certificateTemplates distinguishedname -limit 0 > "%OUT%\adcs_enterprise_cas.log" 2>&1
type "%OUT%\adcs_enterprise_cas.log"

echo.
echo === CERTIFICATE TEMPLATES (full list, signed dsquery) ===
echo --- All templates ---
dsquery.exe * "CN=Configuration,DC=%DOM%,DC=local" -filter "(objectClass=pKICertificateTemplate)" -attr cn displayname msPKI-Template-Schema-Version msPKI-Certificate-Name-Flag msPKI-Enrollment-Flag msPKI-RA-Signature pKIExtendedKeyUsage distinguishedname -limit 0 > "%OUT%\adcs_all_templates.log" 2>&1
echo --- Saved to adcs_all_templates.log ---

echo.
echo === TEMPLATES LIKELY VULNERABLE TO ESC1 ===
echo --- Look for: ENROLLEE_SUPPLIES_SUBJECT (ENROLLEE_SUPPLIES_SUBJECT flag bit 0x1) + low RA-Signature ---
findstr /i "0x1" "%OUT%\adcs_all_templates.log" | findstr /i "cn displayname" > "%OUT%\adcs_esc1_candidates.log" 2>&1
echo --- ESC1 candidates (matches show ENROLLEE_SUPPLIES_SUBJECT) ---
type "%OUT%\adcs_esc1_candidates.log"

echo.
echo === CA FLAGS - ESC6 EDITF_ATTRIBUTESUBJECTALTNAME2 CHECK ===
echo --- Method: certutil on each CA, look for 0x00080000 in flags ---
for /f "tokens=*" %%H in ( 'type "%OUT%\adcs_caservers.log"' ) do (
    echo --- Checking %%H ---
    certutil.exe -CAInfo "%%H" 2>&1 | findstr /i "flag" > "%OUT%\adcs_cainfo_%%H.log" 2>&1
    type "%OUT%\adcs_cainfo_%%H.log"
)

echo.
echo === LOCAL MACHINE ENROLLMENT CONTEXT ===
certutil.exe -enrollment -user > "%OUT%\adcs_user_enroll.log" 2>&1
certutil.exe -enrollment -machine > "%OUT%\adcs_machine_enroll.log" 2>&1

echo.
echo === Done. Files in %OUT% ===
dir "%OUT%\adcs_*"
pause
endlocal
