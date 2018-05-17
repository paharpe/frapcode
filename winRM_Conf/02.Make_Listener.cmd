@echo on
REM ===============================================================================================
REM Name: 02.Make_Listener.cmd
REM What: In order to install winRM >to put file on multiple VM's<- an HTTP's listener has to be
REM       created first. 
REM May 2018
REM ===============================================================================================

REM INIT
REM ===============================================================================================
set OUTFILE="C:\users\administrator\desktop\listener.cmd"

REM Step 1: Check if listener already exists
REM ===============================================================================================
winrm enumerate winrm/config/Listener | grep HTTPS | wc -l > %OUTFILE%
set /p EXISTCOUNT=< %OUTFILE% 
IF %EXISTCOUNT% GTR 0 (
  Echo Listener already exists !
  Pause
  exit
)

REM Step 2: Get thumbprint and write value to outfile
REM ===============================================================
powershell get-childitem -path cert:\localmachine\my | grep -i CN=sw | grep -vi hent | cut -d" "  -f1 > %OUTFILE%

REM Step 3: Read outfile in store value in variable
REM ===============================================================
set /p THUMBPRINT=< %OUTFILE%  

REM echo winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="%computername%"; CertificateThumbprint="%THUMBPRINT%"} >> %OUTFILE%

REM Step 4: Execute the command
REM ================================================================
call winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="%computername%"; CertificateThumbprint="%THUMBPRINT%"}
pause	
REM notepad %OUTFILE%

REM Step 5: Remove outfile
erase %OUTFILE%