 ################################################################### 
# Functions 
################################################################## 

function Write-Log([string]$strLogData) 
{ 
  $strDate=(Get-Date).ToString("yyyyMMdd")  
  $strTime=(Get-Date).ToString("HHmmss") 
  "$strHostName-$strDate-$strTime : $strLogData" >> $strLogFile 
} 

function End-of-Job() 
{ 
  Write-Log $strLogBar 
  Write-Log "Run completed" 
  Write-Log $strLogBar 

  Exit 
} 

function Write-Log-Head()
{
  Write-Log $strLogBar 
  Write-Log "Start run" 
  Write-Log $strLogBar
}

function Write-Report-Head()
{
#Reportheader 
  $strDate=(Get-Date).ToString("yyyyMMdd")  
  $strTime=(Get-Date).ToString("HHmmss") 
  Write-Output " "                                   > $strAtt_Filename
  Write-Output $strLogBar                           >> $strAtt_Filename
  Write-Output "Reporting Decos failed scans"       >> $strAtt_Filename
  Write-Output "Host Name   : $strHostName"         >> $strAtt_Filename
  Write-Output "Server role : $strAppRole"          >> $strAtt_Filename
  Write-Output "Appl Name   : $strAppName"          >> $strAtt_Filename
  Write-Output "Om/op       : $strDate / $strTime " >> $strAtt_Filename  
  Write-Output $strLogBar                           >> $strAtt_Filename
  Write-Output " "                                  >> $strAtt_Filename
}

function Get-Failed-Scans()
{
  Get-ChildItem -Path $strFailed_Input_Path | Add-Content $strAtt_Filename
}

　
function Send-Mail($strSender, $strRecipient, $strSubject, $strAttach)
{
  $objMessage= new-object Net.Mail.MailMessage
  $objAttach = new-object Net.Mail.Attachment($strAttach)
  $objSMTP   = new-object Net.Mail.SmtpClient($strSMTP_Server)

  $objMessage.From=$strSender
  $objMessage.To.Add($strRecipient)
  $objMessage.Subject=$strSubject
  $objMessage.Body=“Geachte,`n`nBijgaand treft u een overzicht met bestanden in de \failed directory. `n`nMet vriendelijke groet,`nKPN Business Operations`nDCO Government”
  $objMessage.Attachments.Add($strAttach)

  $objSMTP.UseDefaultCredentials=$true
  $objSMTP.Send($objMessage)
}

　
########## 
# Init (1) 
########## 

#Makeup 
$strLogBar            = "==========================================================================================================" 

$strBase_Path         = "c:\management"
$strFailed_Send_Path  = $strBase_Path +"\scripts\SendFailedDecosScans"
$strFailed_Input_Path = "e:\DECOS\DATA\barcode\failed\"

####################
# Mailfunc variables
####################
$strSender_Mail_Address  = "Decos_Noreply@KPN.com"
$strReceipt_Mail_Address = "peter.harpe@kpn.com"
$strSMTP_Server          = "10.207.0.39"
$strAtt_Filename         = $strFailed_Send_Path + "\failed_scans.txt"

$strHostName             = hostname
$strAppRole              = facter application_role
$strAppName              = facter application_name

$bDebug                  = $False 

###################
# Logfile  
###################
# Compose logfile: $strLogBase$strDate$strLogExt 
#1) $strMyName will made equal to the scriptname, for example: AppendIP 
#2) after including $strLogBase log will be then: AppendIP- 
#3) after including $strDate       log will be then: AppendIP-22-03-2016   
#4) after including $strLogExt  log will be then: AppendIP-22-03-2016.log  

#Get filename of this script, the first part of the logfile will be made the equal to this. 
$strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a logfilename 
$strLogBase  = $strMyName + "-" + $strDate 
$strLogExt   = ".log" 
$strLogFile  = $strBase_Path + "\log\$strLogBase$strLogExt" 

　
#################################################################################################### 
# Run
#################################################################################################### 
Write-Log-Head

Write-Report-Head

Get-Failed-Scans

Send-Mail $strSender_Mail_Address $strReceipt_Mail_Address "Overzicht bestanden in directory \failed" $strAtt_Filename

#################################################################################################### 
End-of-Job
#################################################################################################### 
