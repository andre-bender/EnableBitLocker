echo off
echo.
echo  =============================================================
echo  = BitLocker Activation Script by Andre Bender		  =
echo  = ALHO Group Services GmbH				  =
echo  =============================================================

chcp 1252>nul

set test /a = "qrz"
set ue=ü

chcp 850>nul

for /F "tokens=2 delims= " %%A in ('manage-bde.exe -status %systemdrive% ^| findstr "Verschl%ue%sselungsmethode:"') do (
	if "%%A"=="AES" goto EncryptionCompleted)

for /F "tokens=2 delims= " %%A in ('manage-bde.exe -status %systemdrive% ^| findstr "Verschl%ue%sselungsmethode:"') do (
	if "%%A"=="XTS-AES" goto EncryptionCompleted)

for /F "tokens=2 delims= " %%A in ('manage-bde.exe -status %systemdrive% ^| findstr "Verschl%ue%sselungsmethode:"') do (
	if "%%A"=="Kein" goto TPMActivate)

goto ElevateAccess

:TPMActivate

powershell Get-BitlockerVolume

echo.
echo  =============================================================
echo  = Es sieht aus als wäre (%systemdrive%\) noch nicht         =
echo  = verschlüsselt. BitLocker wird aktiviert.                  =
echo  =============================================================
for /F %%A in ('wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get IsEnabled_InitialValue ^| findstr "TRUE"') do (
if "%%A"=="TRUE" goto nextcheck
)

goto TPMFailure

:nextcheck
for /F %%A in ('wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get IsEnabled_InitialValue ^| findstr "TRUE"') do (
if "%%A"=="TRUE" goto starttpm
)

goto TPMFailure

:starttpm
powershell Initialize-Tpm

:bitlock
manage-bde -protectors -disable %systemdrive%
bcdedit /set {default} recoveryenabled No
bcdedit /set {default} bootstatuspolicy ignoreallfailures

manage-bde -protectors -delete %systemdrive% -type RecoveryPassword
manage-bde -protectors -add %systemdrive% -RecoveryPassword
for /F "tokens=2 delims=: " %%A in ('manage-bde -protectors -get %systemdrive% -type recoverypassword ^| findstr "       ID:"') do (
	echo %%A
	manage-bde -protectors -adbackup %systemdrive% -id %%A
)

manage-bde -protectors -enable %systemdrive%
manage-bde -on %systemdrive% -SkipHardwareTest

:VerifyBitLocker
for /F "tokens=2 delims= " %%A in ('manage-bde -status %systemdrive% ^| findstr "Verschl%ue%sselungsmethode:"') do (
	if "%%A"=="AES" goto EncryptionCompleted
	)

for /F "tokens=2 delims= " %%A in ('manage-bde -status %systemdrive% ^| findstr "Verschl%ue%sselungsmethode:"') do (
	if "%%A"=="XTS-AES" goto EncryptionCompleted
	)

for /F "tokens=2 delims= " %%A in ('manage-bde -status %systemdrive% ^| findstr "Verschl%ue%sselungsmethode:"') do (
	if "%%A"=="Kein" goto EncryptionFailed
	)
	
:EncryptionFailed
echo.
echo  =============================================================
echo  = Verschlüsselung auf Festplatte (%systemdrive%\) failed.   =
echo  = Die Aktivierung des BitLockers hat nicht funktioniert.    =
echo  = Es wurde kein AES oder XTS-AES Status ermittelt.	  =
echo  =============================================================

echo Closing session in 30 seconds...
TIMEOUT /T 30 /NOBREAK
Exit

:TPMFailure
echo.
echo  =============================================================
echo  = Verschlüsselung auf Festplatte (%systemdrive%\) failed.   =
echo  = Eventuell ist der TPM Chip im BIOS deaktiviert.           =
echo  = TPMPresent und TPMReady muss dafür auf True stehen.       =
echo  =                                                           =
echo  = TPM Status sieht wie folgt aus:                           =
echo  =============================================================

powershell get-tpm

echo Closing session in 30 seconds...
TIMEOUT /T 30 /NOBREAK
Exit

:EncryptionCompleted
echo.
echo  =============================================================
echo  = Sieht aus als wäre (%systemdrive%) bereits verschlüsselt  =
echo  = oder wird gerade verschlüsselt. 			  =
echo  = Der Verschlüsselungsstatus sieht wie folgt aus:           =
echo  =============================================================

powershell Get-BitlockerVolume

echo Closing session in 10 seconds...
TIMEOUT /T 10 /NOBREAK
Exit

:ElevateAccess
echo  =============================================================
echo  = Das Skript muss als Administrator gestartet werden.       =
echo  = Bitte das Skript rechtsklicken und als Admin ausführen.   =
echo  =============================================================

echo Closing session in 20 seconds...
TIMEOUT /T 20 /NOBREAK
Exit
