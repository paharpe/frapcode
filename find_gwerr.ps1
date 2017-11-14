####################################################################################################
# Naam: find_gwerr.ps1
# Doel: Het via e-mail melden van het aantal malen dat een bepaalde foutmelding in de PView5 Wrapper
#       logfile voorkomt.
#
# PH, november 2017
####################################################################################################
$strScriptPath="C:\management\Scripts"

####################################################################################################
# Includes
####################################################################################################
. "$strScriptPath\PView5_Check\cleanup-log.ps1"
. "$strScriptPath\PView5_Check\get-vars.ps1"
####################################################################################################
# Init
####################################################################################################
$strHostName=hostname
$strString2Find="Bad Gateway"
$strDateNow=(Get-Date).ToString("yyyyMMdd")  

$strWrapper="wrapper"
$strWrapperPath="D:\program files\ADP\workforce\5.0\wrapper"
$strWrapperFile=$strWrapper+"."+$strDateNow+".log"
$strWrapperFull=$strWrapperPath+"\"+$strWrapperFile

$strLogPath="C:\management\log"
$strLogFile="Pview5_errors"
$strLogFull=$strLogPath+"\"+$strLogFile+"_$strDateNow.log"
$strCountPath=$strScriptPath+"\Pview5_Check\counters"$strCountFile="Pview5_errorcount_$strDateNow.log"$strCountFull=$strCountPath+"\"+$strCountFile

$intKeep=31
$strSender=get_var "from"
$strRecipient=get_var "to"
$strCC=get_var "cc"
$strSMTP=get_var "smtp"
$strSubject=get_var "subject"

$strBodyText= "Geachte,`n`nU ontvangt dit bericht om u te informeren over het aantal malen dat er`n"
$strBodyText=$strBodyText+"in de wrapper.log file van vandaag '$strString2Find' foutmeldingen zijn aangetroffen." 
$strBodyText_signature="`n`nMet vriendelijke groet,`nKPN Business Operations`nDCO Government`ncuoverheid@kpn.com"

$strLogBar= "==========================================================================================================" 
 
####################################################################################################
# Functions
####################################################################################################
function write-log([string]$strLogData) 
{ 
  $strDate=(Get-Date).ToString("yyyyMMdd")  
  $strTime=(Get-Date).ToString("HHmmss") 
  "$strHostName-$strDate-$strTime : $strLogData" >> $strLogFull 
} 
 
 function write-log-Head()
{
  write-log $strLogBar 
  write-log "Run started" 
  write-log $strLogBar
}

# Maintain counterfile # When today's counterfile does not exist ( yet / anymore )# generate a new one holding initial value of 0 error(s)function init_countfile(){  # Count file does not exist yet ? Create the su*er  if (!( Test-Path ( $strCountFull )))  {    $intErrorcount=0;    echo $intErrorcount > $strCountFull;    write-log "New countfile created: $strCountFull"  }  else  {       $intErrorcount=Get-Content $strCountFull -First 1  }  return $intErrorCount;}
# Find searchstring in logfile and format result
#
# Raw result:
# (1) wrapper.20171108.log:125815:FINEST|7548/0|17-11-08 16:04:02|16:04:02,451 ERROR [Javascript] [DD7C8AA2BF56FDEE2F5B97B497860674] [pv50_
#     shp_prod] [023575] (WebComposerFacade).javascript 16:4:2,632===message : Bad Gateway
# (2) wrapper.20171108.log:125823:FINEST|7548/0|17-11-08 16:19:50|16:19:50,757 ERROR [Javascript] [DD7C8AA2BF56FDEE2F5B97B497860674] [pv50_
#     shp_prod] [023575] (WebComposerFacade).javascript 16:19:50,974===message : Bad Gateway
# ... 
#
# Formatted result:
# 16:04:02 16:19:50 ....
#
function get_error([string] $strFunction)
{

  if (!( Test-Path ( $strWrapperFull )))  {
    write-log "Inputfile: $strWrapperFull does not exist !"
    return -1
  }
  else
  {
    write-log "Searching in file: $strWrapperFull"
    
    $strErrors=((Select-String -Path $strWrapperFull -Pattern $strString2Find | cut -d" " -f2 | grep -v ^\[ | grep -v ^"(" ) | Where { $_ -ne "" } | ForEach { $_.Replace(" ","") } | cut -d"|" -f1)
 
    if ( $strFunction -eq "count" )
    { 
      return $strErrors.count;
    } 
    else
    {
      return $strErrors;
    }
  }
}

# Check if parm has a valid e-mail adress pattern
function check_mailaddress($strMailAddress)
{
 try
 {
  $objChk = New-Object System.Net.Mail.MailAddress($strMailAddress)
  return $true
 }
 catch
 {
  return $false
 }
}

function End-of-Job() 
{ 
  Write-Log $strLogBar 
  Write-Log "Run completed" 
  Write-Log $strLogBar 
 
  Exit 
} 

function Send-Mail([string] $intErrorCount)
{
  $objMessage= new-object Net.Mail.MailMessage
  $objSMTP   = new-object Net.Mail.SmtpClient($strSMTP)

  if ( !(check_mailaddress $strSender ))
  {
    write-log "From:$strSender is not a valid e-mailadres !"
    exit
  }
  $objMessage.From=$strSender
  
  if ( !(check_mailaddress $strRecipient ))
  {
    write-log "To:$strRecipient is not a valid e-mailadres !"
    exit
  }
  $objMessage.To.Add($strRecipient)

  # CC's toevoegen in een loop
  $arrCCs = $strCC -split ';'
  if ($arrCCs -ne $null)
  {
    foreach ($strCC in $arrCCs)
    {      
      if   ( $strCC -ne $null )
      {
        if ( !(check_mailaddress $strCC ))
        {
          write-log "CC:$strCC is not a valid e-mailadres !"
          exit
        }
        echo $strCC
        $objMessage.CC.add($strCC)
       }
    }
  }
  
  $objMessage.Body=$strBodyText

  # $objMessage.Attachments.Add($strAttach)
  
  # Hieronder wordt de 'pseudo variabele' @intErrorCount vervangen door het 'echte' aantal
  $strSubject=$strSubject.Replace("@intErrorCount",$intErrorCount);
  $objMessage.Subject="$strSubject ($strWrapperFile)"
    
  $objMessage.Body=$strBodyText + $strBodyText_signature
  $objSMTP.UseDefaultCredentials=$true
  $objSMTP.Send($objMessage)    

  $strMailRC=$?

  Write-log "Returncode from sendmail: $strMailRC"

}


###################################################################################################
# Main line
###################################################################################################

write-log-Head
 
Cleanup-log $strLogPath $strLogFile $intKeep
Cleanup-Log $strWrapperPath $strWrapper $intKeep

write-log "Retrieved mail vars: from:$strSender / to:$strRecipient / cc:$strCC / smtp:$strSMTP"

$intErrorcount=init_countfile;

$strErrorTimes=get_error " ";
$intErrorCount_New=get_error "count";

if ( $intErrorCount_New -ge 0)
{
  #echo "Oud: $intErrorcount "  #echo "New: $intErrorCount_New"
  if ( $intErrorCount_New -ne $intErrorcount )
  {
    #save the new number of errors to the error-counterfile
    echo $intErrorCount_New > $strCountFull

    write-log "Number of errors has changed from:  $intErrorCount to: $intErrorCount_New"
    write-log "Time(s): $strErrorTimes"
    # Send-Mail    
  }
  else
  {
    write-log "No change in number of errors ($intErrorCount_New)"
  }
 
}

# In overleg met Rob Noorbeek en 'Staffa' is besloten om de e-mail op een 2-tal vaste tijdstippen
# uberhaupt te versturen ( ongeacht hoeveel keer de foutmelding in de logfile is aangetroffen
Send-Mail($intErrorCount_New)  

End-of-Job