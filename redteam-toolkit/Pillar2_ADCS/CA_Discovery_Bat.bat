@echo off
setlocal enabledelayedexpansion

REM ============================================
REM CA_Discovery_Bat.bat - Find all CAs + their info
REM Uses ONLY signed certutil.exe + dsquery.exe
REM Output: %TEMP%\cadisc_*.log
REM ============================================

set "OUT=%TEMP%"
set "DOM=lioncapital"

echo.
echo === AD CS ROOT CAs (auto-discovery) ===
certutil.exe -ADCA > "%OUT%\cadisc_cas.log" 2>&1
type "%OUT%\cadisc_cas.log"

echo.
echo === AD CS SUBORDINATE CAs ===
certutil.exe -ADCA | findstr /i "CN=" > "%OUT%\cadisc_ca_names.txt"
for /f "tokens=*" %%H in ('type "%OUT%\cadisc_ca_names.txt"') do (
    certutil.exe -CAInfo "%%H" >> "%OUT%\cadisc_cainfo_%%H.log" 2>&1
)
dir "%OUT%\cadisc_cainfo_*"

echo.
echo === ALL TEMPLATES ===
certutil.exe -CATemplates > "%OUT%\cadisc_templates.log" 2>&1
type "%OUT%\cadisc_templates.log"

echo.
echo === ALL ENTERPRISE CAs (via LDAP, signed dsquery) ===
dsquery.exe * "CN=Configuration,DC=%DOM%,DC=local" -filter "(objectClass=pKIEnrollmentService)" -attr cn dnsHostname certificateTemplates -limit 0 > "%OUT%\cadisc_enterprise_cas.log" 2>&1
type "%OUT%\cadisc_enterprise_cas.log"

echo.
echo === ALL TEMPLATES (via LDAP, signed dsquery) ===
dsquery.exe * "CN=Configuration,DC=%DOM%,DC=local" -filter "(objectClass=pKICertificateTemplate)" -attr cn displayname msPKI-Certificate-Name-Flag msPKI-Enrollment-Flag pKIExtendedKeyUsage msPKI-RA-Signature distinguishedname -limit 0 > "%OUT%\cadisc_all_templates.log" 2>&1
type "%OUT%\cadisc_all_templates.log"

echo.
echo === TEMPLATES WITH SAN-SPECIFIER FLAGS (ESC1 candidates) ===
echo --- Look for msPKI-Certificate-Name-Flag = 0x1 (ENROLLEE_SUPPLIES_SUBJECT) ---
findstr /i "0x1" "%OUT%\cadisc_all_templates.log" > "%OUT%\cadisc_esc1_candidates.log" 2>&1
type "%OUT%\cadisc_esc1_candidates.log"

echo.
echo === CA FLAGS PER CA (look for ESC6: 0x00080000) ===
echo --- Method: certutil on each CA, look for 0x80000 (EDITF_ATTRIBUTESUBJECTALTNAME2) ---
for /f "tokens=*" %%H in ('type "%OUT%\cadisc_ca_names.txt"') do (
    certutil.exe -CAInfo "%%H" 2>&1 | findstr /i "0x80000" >> "%OUT%\cadisc_esc6_candidates.log" 2>&1
)
type "%OUT%\cadisc_esc6_candidates.log"

echo.
echo === CERTIFICATE REQUEST RESULTS (show what certs YOU have) ===
certutil.exe -store My > "%OUT%\cadisc_my_certs.log" 2>&1
type "%OUT%\cadisc_my_certs.log"

echo.
echo === WEB ENROLLMENT CHECK ===
echo --- Method: certsrv URL accessible? ---
curl.exe -I "http://pwnaddbls01.lioncapita.local/certsrv/" 2>&1 | findstr /i "HTTP\|Server" >> "%OUT%\cadisc_web_enroll.log"

echo.
echo === Done ===
dir "%OUT%\cadisc_*"
pause
endlocal
