^s::
;************************************************************************************
; Purp: Automate vRealize snapshots using an inputfile containing VM's
; PH, 2017-10-13
;
; Prereqs
; -------------------------------------------------
; Assuming:
; Items      => Machines
; Eigenaar   => Alle groepen die ik beheer
; Cursor     => Positioned in the search box
;
;************************************************************************************

;********************
; Teststuff
;********************
;            X , Y
; MouseMove, 82, 312
; Return


;******************
;* Check windowname
;******************
; Execution only valid in a specific browswer window !
WinGetTitle, Title, A
; if ( Title <> "KPN SH portal - Internet Explorer" )
if ( Title <> "KPN SH portal - Google Chrome" )
{
  MsgBox, You cannot run this macro in this window ( %Title% ) !   
  Return
}

;**************************************************************************
; INIT
;**************************************************************************
FormatTime, CurrentDateTime,, yyyyMMdd

;**************************************************************************
;Set inputfile which should contain VM names
;**************************************************************************
host_file=C:\Users\pharpe\Desktop\AHK\SnapShot\SnapShotVMs.txt

IfNotExist, %host_file%
{
    MsgBox, The target file ( %host_file% ) does not exist.
    Return
}

;Select possible existing text in the searchbox so it will be overwritten by %VM% value
Send, ^a

;***************************************************************************
; Main line
;***************************************************************************
Loop
{
  FileReadLine, VM, %host_file%, %A_Index%
  if not ErrorLevel
  {
    ; Compose snapshot name
    ;----------------------
    snap_name=%vm%_Snap_%CurrentDateTime%

    ; Put the VM name in the searchbox
    ;---------------------------------
    Send, %VM%
    Send, {enter}

    ; Wait for the specific VM to be selected and presented
    ;------------------------------------------------------
    Sleep, 3000

    
    Send, {tab}{tab}{tab}{tab}{tab}
    Send, {tab}{tab}

    ; Position and Click on the (first and only) selected VM
    MouseClick, left, 330, 305

    ; Give it some time to load
    Sleep, 3000
    
    ; Click on "Create a Snapshot GOV"
    MouseClick, left, 1800, 285 

    ; Give it some time to open the next form
    sleep, 6000

    ;**************************************************************************
    ; Beschrijving
    ;**************************************************************************
    send, %snap_name%

    ; And relax for a sec.
    sleep, 1000

    send {tab}

    ;**************************************************************************
    ; Redenen
    ;**************************************************************************
    send, %snap_name%

    ;**************************************************************************
    ; And relax for a sec
    ;**************************************************************************
    sleep, 1000

    ;**************************************************************************
    ; Click on "Volgende"
    ;**************************************************************************
    MouseClick, left, 1760, 980

    ;**************************************************************************
    ; And relax for a sec or two
    ;**************************************************************************
    sleep, 2000

    ;**************************************************************************
    ; Snapshot name. The name.....
    ;**************************************************************************
    send, %snap_name%
    sleep, 1000

    ;*************************************************************************
    ; Number of days.... ( Every time add 18 dots to 318(=1 Day) to get
    ; a day extra thru the radiobuttons )
    ;*************************************************************************
    ; 1 Day
    ; MouseClick, left, 739, 318
    ; 2 Days
    ; MouseClick, left, 739, 336 
    ; 3 Days
    MouseClick, left, 739, 354
    ; 4 Days
    ; MouseClick, left, 739, 372
    ; 5 Days
    ; MouseClick, left, 739, 390
    ; 6 Days
    ; MouseClick, left, 739, 408
    ; 7 Days
    ; MouseClick, left, 739, 426 

    sleep, 1000
    ;***********************************************************************
    ; Indienen !
    ;***********************************************************************
    MouseClick, left, 1760, 980
    ;Wait a minute !
    sleep, 3000
   
    ;************************************************************************
    ; Annuleren !!
    ;************************************************************************
    ; MouseClick, left, 1840, 980   
    ; sleep, 3000
    ; MouseMove, 1840,20 
   
    ;************************************************************************
    ; Click the OK button
    ;************************************************************************
    MouseClick, Left, 82, 312

    ;*************************************************************************
    ; Click in the searchbox
    ;*************************************************************************
    MouseClick, Left, 1760, 200

    ;*************************************************************************
    ; And select all text to overwrite it in a new iteration with a new VM
    ;*************************************************************************
    Send, ^a
  }
}