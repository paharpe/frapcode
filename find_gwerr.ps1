####################################################################################################
# Naam: find_gwerr.ps1
# Doel: Het via e-mail melden van het aantal malen dat een bepaalde foutmelding in de PView5 Wrapper
#       logfile voorkomt.
#
# PH, november 2017
#
# Changed Wrapperpath from D:\Program files\..5.0\wrapper
#                       to D:\Program files\..5.1\wrapper                            (PH,2017-11-17)
# Changed Wrapperpath from D:\Program files\..5.1\wrapper
#                       to D:\Program files\..5.2\wrapper                            (PH,2017-12-21)
# Changed Wrapperpath from D:\Program files\..5.2\wrapper
#                       to D:\Program files\..5.2.1\wrapper                          (PH,2018-01-11)
# Changed logfile cleaning by #. Wrapper*.log files are archived by another proces   (PH,2018-03-14)
# Changed Wrapperpath from D:\Program files\..5.2.1\wrapper
#                       to D:\Program files\..5.3\wrapper                            (PH,2018-05-18)
# Changed Wrapperpath from D:\Program files\..5.3\wrapper
#                       to D:\Program files\..5.4\wrapper                            (PH,2018-07-27)
#
# Changed into dynamic determined Wrapperpath                                        (PH,2018-08-07)
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

# Pview5 wrapper Base path
$strWrapperBase="D:\program files\ADP\workforce"
$strPVersion=(Get-ChildItem $strWrapperBase `
                                            | ?{ $_.PSIsContainer } `
                                            | Where-Object { $_.Name -match '^[0-9].[0-9]' } `
                                            | Sort-Object -Descending `
                                            | Select-Object -ExpandProperty Name -First 1 )
# Now has a value like:  D:\program files\ADP\workforce\5.2
$strWrapperPath=$strWrapperBase+ "\"+$strPVersion

$strDateNow=(Get-Date).ToString("yyyyMMdd")  
# TESTDATE $strDateNow="20171115"
$strWrapper="wrapper"
$strWrapperFile=$strWrapper+"."+$strDateNow+".log"

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

$strBodyText= "Geachte,`n`nU ontvangt dit bericht om u te informeren over het aantal keer dat er`n"
$strBodyText=$strBodyText+"in de wrapper.log file van vandaag '$strString2Find' foutmeldingen zijn aangetroffen." 
$strBodyText_signature="`n`nMet vriendelijke groet,`nKPN Business Operations`nDCO Government`ncuoverheid@kpn.com"

$strLogBar= "==========================================================================================================" 
 
####################################################################################################
# Functions
####################################################################################################
function Write-Log([string]$strLogData) 
{ 
  $strDate=(Get-Date).ToString("yyyyMMdd")  
  $strTime=(Get-Date).ToString("HHmmss") 
  "$strHostName-$strDate-$strTime : $strLogData" >> $strLogFull 
} 
 
 function Write-Log-Head()
{
  Write-Log $strLogBar 
  Write-Log "Run started" 
  Write-Log $strLogBar
}

# Maintain counterfile # When today's counterfile does not exist ( yet / anymore )# generate a new one holding initial value of 0 error(s)function init_countfile(){  # Count file does not exist yet ? Create the su*er  if (!( Test-Path ( $strCountFull )))  {    $intErrorcount=0;    echo $intErrorcount > $strCountFull;    Write-Log "New countfile created: $strCountFull"  }  else  {       $intErrorcount=Get-Content $strCountFull -First 1  }  return $intErrorCount;}
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
  if ( !( Test-Path ( $strWrapperPath ) ) )
  {
    Write-Log Wrapper base path ( $strWrapperPath ) does not exist !
    return -1   
  }

  # Find and get today's wrapper file: ( wrapper.yyyymmdd.log )
  $strWrapperFile_current=(Get-ChildItem $strWrapperPath -recurse -include $strWrapperFile) | Select-Object LastWriteTime, FullName | Sort-Object LastWriteTime | Select-Object -ExpandProperty FullName  -Last 1 
  if ( $strWrapperFile_current -eq $null )
  {
    Write-Log "There is no such wrapper file: $strWrapperFile !"
    return -1   
  }  
  else
  {

    Write-Log "Searching in: $strWrapperFile_current"

    # This selectstring is causes too many finding and is deprecated
    # $strErrors=((Select-String -Path $strWrapperFull -Pattern $strString2Find | cut -d" " -f2 | grep -v ^\[ | grep -v ^"(" ) | Where { $_ -ne "" } | ForEach { $_.Replace(" ","") } | cut -d"|" -f1)
    
    $strErrors=(Select-String -Path $strWrapperFile_current -Pattern $strString2Find )
 
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
    Write-Log "From:$strSender is not a valid e-mailadres !"
    exit
  }
  $objMessage.From=$strSender
  
  if ( !(check_mailaddress $strRecipient ))
  {
    Write-Log "To:$strRecipient is not a valid e-mailadres !"
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
          Write-Log "CC:$strCC is not a valid e-mailadres !"
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
  try
  {
    $objSMTP.Send($objMessage)    

    $strMailRC=$?
  
    Write-Log "Returncode from sendmail: $strMailRC"
  }

  catch
  {
     Write-Log "Sendmail failed and ran into an error !"
  }
}


###################################################################################################
# Main line
###################################################################################################

Write-Log-Head
 
Cleanup-log $strLogPath $strLogFile $intKeep
# See changelog Cleanup-Log $strWrapperPath $strWrapper $intKeep

Write-Log "Retrieved mail vars: from:$strSender / to:$strRecipient / cc:$strCC / smtp:$strSMTP"

$intErrorcount=init_countfile;

# $strErrorTimes=get_error " ";
$intErrorCount_New=get_error "count";

if ( $intErrorCount_New -ge 0)
{
  #echo "Oud: $intErrorcount "  #echo "New: $intErrorCount_New"
  if ( $intErrorCount_New -ne $intErrorcount )
  {
    #save the new number of errors to the error-counterfile
    echo $intErrorCount_New > $strCountFull

    Write-Log "Number of errors has changed from:  $intErrorCount to: $intErrorCount_New"    
  }
  else
  {
    Write-Log "No change in number of errors ($intErrorCount_New)"
  }   
}
else
{
  Write-Log "Function get_error returned an error. Mail will NOT be sent !"
  End-of-Job
}

# In overleg met Rob Noorbeek en 'Staffa' is besloten om de e-mail op een 2-tal vaste tijdstippen
# uberhaupt te versturen ( ongeacht hoeveel keer de foutmelding in de logfile is aangetroffen
Send-Mail($intErrorCount_New)  

End-of-Job