# EnableBitLocker for Windows 10/11

Info: This script only works on a german language system, since the function 'findstr' searches for german words.
For english systems you could replace "Verschlüsselungsmethode" with "Encryption Method" - should work.

This script enables BitLocker on C: and checks for TPM chip. If TPM is disabled, the TPM will be activated. 
If no TPM is detected or drive is already encrypted, the script will be skipped to end.

Just assign this batch to a GPO that runs this script. 

I recommend creating a GPO with the following settings:
- Plan a task
- Run the task with a delay of 30 seconds after logon
- Assign SYSTEM User with high priviliges
- Configure the action like this: powershell.exe Name of Script.bat
