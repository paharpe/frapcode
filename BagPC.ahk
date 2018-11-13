;^k::

;********************************************************************
;* Naam: BagPC.ahk
;*
;* Doel: Postcode update exe van Decos unattended uitvoeren
;*
;* Nodig: C:\Management\Scripts\bagpc.config : points to BAGPC.exe 
;*        C:\Management\log
;* 
;* Alle andere benodigde settings worden uit het bagpc.config bestand
;* gelezen
;*       
;* Door: P.A. Harpe, 26-10-2018
;********************************************************************

;********************************************************************
;FUNCTIONS
;********************************************************************

;************************************************
WriteScreenContents(ScreenToRead)
;************************************************
{
  ; Write screen-contents to logfile
  WinGetText, output, %ScreenToRead%
  StringReplace,output, output,`n,,A
  WriteLog( output )
}

;************************************************
WriteLog(TextToLog)
;************************************************
{
  global Logfile
  global debug
  FormatTime, CurrentDateTime,, yyyyMMdd HH:mm:ss
  FileAppend, %CurrentDateTime%: %TextToLog%`n, %Logfile%

  if ( debug = 1 )
  {
    MsgBox, %TextToLog%
  }
}

;***********************************************
Einde()
;***********************************************
{
  MsgBox, BagPc has ended
  exit
}


;********************************************************************
; INIT
;********************************************************************
#SingleInstance force

Basepath=C:\management
Locations_ini=%Basepath%\Scripts\bagpc.config
Logdir=%Basepath%\log
Logfile=%Logdir%\ahl.log
Destdir=C:\users\pharpe\downloads
Unzip="C:\Program Files\7-Zip\7z.exe"
;
BAGHead=Decos Postcode-update (BAG)
; POCOHead=Decos Postcode-update oktober 2018 (BAG)
Ext_Count=0


;********************************************************************
; CHECKS
;********************************************************************

;***********************************************
; Logdirectory exists ????
;***********************************************
IfNotExist, %Logdir%
{
  FormatTime, CurrentDateTime,, yyyyMMdd HH:mm:ss
  MsgBox, %CurrentDateTime% - Logdirectory %Logdir% does not exist !
  Einde() 
} 

;***********************************************
; Configfile exists ????
;***********************************************
if !FileExist(Locations_ini)
{
  Msg=Configfile %Locations_ini%  does not exist but NEEDS to be present !  
  WriteLog( Msg )
  Einde() 
} 


;********************************************************************
; PROCESSING
;********************************************************************

;***********************************************
;Inlezen locatie van INI file
;***********************************************
FileRead, BagPC, %Locations_ini%
if ErrorLevel  ; Successfully loaded.
{
  Msg=An error has occurred when reading %Locations_ini%
  WriteLog( Msg )
  Einde() 
}

;************************************************
;Inlezen stuurdata vanuit INI file, het gaat om:
;1 unzip program en path
;2 bagpc file en path
;3 debug, 1=true, 0=false
;************************************************
; Set default values which will be overwritten
; by the config file values
debug=0
BagPC="C:\users\pharpe\downloads"
Unzip="C:\management\Programs\Utils\unzip.exe"


BagPC_vars := Array()
Loop, Read, %Locations_ini%
{
    BagPC_vars.Push(A_LoopReadLine)
}

; Read from the array:
for index, BagPC_var in BagPC_vars
{   
  ; Using "for", both the index (or "key") and its associated value
  ; are provided, and the index can be *any* value of your choosing.
  ; MsgBox % "Element number " . index . " is " . BagPC_var
  
  bagpc_ini := StrSplit(BagPC_var, "=", ".") ; punten(.) doen niet mee
  if ( bagpc_ini[1] = "debug" )
  {
    debug = % bagpc_ini[2]    
  }
  if ( bagpc_ini[1] = "bagpc_path" )
  {
    BagPC = % bagpc_ini[2]
  }
  if ( bagpc_ini[1] = "unzip" )
  {
    Unzip = % bagpc_ini[2]
  }
}

Msg=Retrieved: debug = %debug%
WriteLog( Msg )  

Msg=Retrieved: bagpc path = %BagPC% 
WriteLog( Msg )  

Msg=Retrieved: unzip path = %Unzip% 
WriteLog( Msg )  

;***********************************************
; Check Destination directory ????
;***********************************************
IfNotExist, %Destdir%
{
  Msg=Unzip destination %Destdir%  does not exist !
  WriteLog( Msg )
  Einde() 
} 

;***********************************************
; Check zip executable
;***********************************************
IfNotExist, %Unzip%
{
  Msg=Unzip executable %Unzip%  does not exist !
  WriteLog( Msg )
  Einde() 
} 


;************************************************
;Zoek naar het meest recente BAGPC bestand dat
;nog niet is uitgevoerd
;************************************************

; De Splitpath functie is wel een heeel vreemde...
; Het aantal  komma's bepaalt welk onderdeel van de het fullpath wordt teruggeven
; en de extensie komt dus na de 3e komma 

Loop, %BagPC%\*.zip
{
  SplitPath,A_Loopfilefullpath,,, ext

  if ( ext = "zip" )
  {
     ; msgbox, %A_Loopfilefullpath%
     BagPCzip=%A_Loopfilefullpath%
     SplitPath, A_Loopfilefullpath,,,, BagPCfile
     ;jan2018 | apr2018 | jul2018 | okt2018     
     Ext_Count++
  }
}
if ( Ext_Count <> 1 )
{
  Msg=Error: zipfile %BagPCzip% does not to exist !
  WriteLog( Msg )
  Einde() 
}
else
{  
  Msg=OK zipfile %BagPCzip% Found
  WriteLog( Msg )  
}

;***********************************************
;Unzip the EXE
;***********************************************
; Run, %Unzip% x -y -o%Destdir% %BagPCzip%
Run, %Unzip% -o %BagPCzip% -d %Destdir%
if ErrorLevel = ERROR
{
  Msg=An error occurred unzipping %BagPCzip%
  MsgBox, %Msg%
  WriteLog( Msg )
  Einde()
}
Else
{
  BagPCperiode = % SubStr(BagPCfile, -6)
  BagPCyear= % Substr(BagPCperiode,-3)
  BagPCmonth= % Substr(BagPCperiode,1,3)

  BagPCexe=%Destdir%\%BagPCfile%.exe 
  Msg=%BagPCexe% unzipped succesfully
  WriteLog( Msg )
}


;********************************************
;Convert monthabbrev into full
;********************************************
BagPCmonth_full=unknown
if ( BagPCmonth = "jan" )
{
  BagPCmonth_full=januari
}
else if ( BagPCmonth = "apr" )
{
  BagPCmonth_full=april
}
else if ( BagPCmonth = "jul" )
{
  BagPCmonth_full=juli
}

else if ( BagPCmonth = "okt" )
{
  BagPCmonth_full=oktober
}
else
{
  Msg=%BagPCmonth% is een onbekende maand !
  WriteLog ( Msg )
  Einde()
}

POCOHead=Decos Postcode-update %BagPCmonth_full% %BagPCyear% (BAG)

Msg=Composed window title:%POCOHead%
WriteLog( Msg )

;***********************************************
;Run the EXE
;***********************************************
Run, %BagPCexe%, , Min UseErrorLevel, AiDee  ; Launch maximized and don't display dialog if it fails.

Sleep 3000
WriteLog("Na de sleep van 3000")


;**********************************************
; WHAT??? 
;
;  Als we dit op een server draaien waar geen 
;  (Decos) database aanwezig is, dan zien we 
;  "Decos Postcode-update (BAG)" = variabele
;  %BAGHead%
;
;   Als we dit op een server uitvoeren waar wel 
;   een (Decos) database draait, dan zien we 
;   "Decos Postcode-update oktober 2018 (BAG)" 
;   = variabele %POCOHead%
;**********************************************


;*********************************************
;Zien we: BAGHead=Decos Postcode-update (BAG)?
;*********************************************
IfWinActive, %BAGHead%
{

  WriteScreenContents( BAGHead )


  ControlFocus, OK, %BAGHead% ; Set focus to the OK button


  Sleep 5000
  Send {Enter}

  Msg=No Decos databaseconnection ? Postcode update not succesfull !
  WriteLog( Msg )
  Einde()
}

;*************************************************
;BAGHead=Decos Postcode-update Oktober 2018 (BAG)?
;*************************************************

WinActivate, %POCOHead%
IfWinActive, %POCOHead%
{


  ControlFocus, Start update, %POCOHead%  ; Set focus to the OK button
  
  Msg=OK Postcode update was succesful !
  WriteLog( Msg )
  Sleep 2000

  WriteScreenContents( POCOHead ) 

  Send {Enter}  
}

Sleep 15000
IfWinActive, %BAGHead%
{

  WriteScreenContents( POCOHead ) 
  
  ControlFocus, OK, %BAGHead% ; Set focus to the OK button
  Sleep 2000
  Send {Enter}

  Msg=OK final dialogbox was closed !
  WriteLog( Msg )
}

Einde()
