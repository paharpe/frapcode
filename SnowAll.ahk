^k::
; Execution only valid at IE on a Snow screen !
WinGetTitle, Title, A
if ( Title <> "ServiceNow - Internet Explorer" )
{
  MsgBox, You cannot run this macro in this window ! 
}
else
{ 
  ; ==================================================== 
  ; STEP 1 => ACTIVATE
  ; ====================================================  
  ; Assume we land in field Vendor [Getronics]  
  ; Then, navigate to field State  [New]
  Send, {TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}  
  
  ;3 times an A to change value from [New to Active]
  Send, AAA  
  
  ;We have to get back to field [Assigned to]  
  ;so we need to backtab 6 times 
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}  
  
  ;Wait for 2 secs
  sleep, 2000
  
  ;Goto the last man standing ( Select me )...
  Send, {Down}{Down}
  Send, {Return} 
  
  ;Goto Primary diagnosis field 
  Send, {TAB}{TAB}{TAB}{TAB}{TAB} 
  Send, {TAB}{TAB}{TAB}{TAB}{TAB}
  Send, {TAB}{TAB}{TAB}{TAB}{TAB}
  Send, {TAB}{TAB}{TAB}{TAB}{TAB}
  Send, {TAB}{TAB}  Send, Investigate  
  
  ;Wait for 1 sec
  sleep, 1000  
  
  ;Go back to the [SAVE] button
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB} 
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}
  
  ;Wait for 1 sec 
  Send, {Return}  
  
  ;Wait for 3 sec 
  sleep, 3000 
  
  ; ==================================================== 
  ; STEP 2 => RESOLVE 
  ; ====================================================
  ;Assume we land in field Vendor [Getronics] 
  ;Then, navigate to field State  [Active]  
  
  Send, {TAB}{TAB}{TAB}{TAB}{TAB} 
  Send, {TAB}{TAB}{TAB}
  
  ;R to change value from [Active to Resolve] 
  Send, R  
  
  ;Goto [Closure code] and select "Finished inside domain"  
  Send, {TAB}{TAB}{TAB}{TAB}{TAB}  
  Send, {TAB}{TAB}{TAB}{TAB}{TAB} 
  Send, {TAB}{TAB}{TAB}{TAB}{TAB} 
  Send, {TAB}{TAB}  
  Send, F 
 
  ;Goto [Cause code] and select "Other"  
  Send, {TAB}  Send, O
  
  ;Goto [Breach code] and select "B03 Late resolved - Limited working hours"  
  Send, {TAB}
  Send, BBB
  
  ;Goto [Definive Resolution code] and select "Other" 
  Send, {TAB} 
  Send, OO  
  
  ;Goto [Solution] and enter a string
  Send, {TAB}  
  Send, Known and non-recurring issue; hence closing ticket
  
  ;Wait for 1 sec 
  sleep, 1000

  ;Go back to the [Update] button 
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB} 
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}+{TAB}
  Send, +{TAB}+{TAB}+{TAB}+{TAB}
  
  ;Wait for 1 sec
  Send, {Return}
}
  
Return
