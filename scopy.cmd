@echo on &setlocal enabledelayedexpansion

REM Syntax: scopy "@fullpathANDname" @destdrive
REM         scopy "C:\users\gebruiker\Docs Private\soll.doc" D:

REM What will happen:
REM soll.doc will be copied to D:\2016\users\gebruiker\Docs Private\

REM What??????
REM D:                             has been supplied as second parm
REM 2016                           is the last modification date(YYYY) of the 
REM                                input file
REM \users\gebruiker\Docs Private\ is equal to the path where the input file resides 

REM *******************************************
REM Init
REM *******************************************
set input=%1%
set filename=%1%
set destination=%2%

set filename=%~nx1
set drive=%~d1
set folder=%~p1
set date=%~t1

REM echo The name of the file is %filename%
REM echo It's drive is %drive%
REM echo It's path is %folder%
REM echo It's date is %date%

REM *******************************************
REM get year
REM *******************************************
for /F "tokens=3 delims=- " %%y in ("%date%") do (
   set year=%%y
   REM echo %%b
)

REM *******************************************
REM compose full destinationpath
REM *******************************************
set newpath=%destination%\%year%%folder%

REM *******************************************
REM Create destinationpath
REM *******************************************
if not exist "%newpath%" mkdir "%newpath%"

REM *******************************************
REM Perform the copy
REM *******************************************
echo "about to copy...."
copy /Y %input% "%newpath%"