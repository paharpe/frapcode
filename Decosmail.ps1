############################################################################################# 
# Name        : Decosmail.ps1 
# Purpose     : Send a mail to FB gem.Amsterdam having an attachment with all 
#               files (scans) in the ..\..\..\Failed directory on an Decos Fileserver
# Syntax      : ./Decosmail.ps1 
# Parms       : None
# Dependancies: none 
# Files    (1): Every run file c:\management\scripts\SendFailedDecosScans\failed_scans.txt 
#               is written and sent as an attachment
#          (2): Logfile: Decosmail-dd-mm-yyyy.log  
# Notes       : All settings should be made/changed in the Init (1) section 
# Author      : PH 
# Date        : 2017-08-30 
#############################################################################################  
Set-PSDebug -Trace 0 
　
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
  if ( -Not ( Test-Path $strFailed_Input_Path ))
  {
    Write-Log "'$strFailed_Input_Path' does not exist !"
    end-of-job
  } 
  else
  {
    $intFailedCount=(Get-ChildItem -Path $strFailed_Input_Path | Measure-Object ).Count
    Write-Log "Number of failed objects: $intFailedCount"
    Get-ChildItem -Path $strFailed_Input_Path | Add-Content $strAtt_Filename
  }
}
 
function Send-Mail($strSender, $strRecipient, $strSubject, $strAttach)
{
  $objMessage= new-object Net.Mail.MailMessage
  $objAttach = new-object Net.Mail.Attachment($strAttach)
  $objSMTP   = new-object Net.Mail.SmtpClient($strSMTP_Server)
　
  $objMessage.From=$strSender
  $objMessage.To.Add($strRecipient)
  $objMessage.Subject=$strSubject
  $objMessage.Body=$strBodyText
  $objMessage.Attachments.Add($strAttach)
　
  $objSMTP.UseDefaultCredentials=$true
  $objSMTP.Send($objMessage)
}
　
 
#################### 
# Init (1) 
####################
　
####################
# Makeup
#################### 
$strLogBar            = "==========================================================================================================" 
　
####################
# Paths
####################
$strBase_Path         = "c:\management"
$strFailed_Send_Path  = $strBase_Path +"\scripts\SendFailedDecosScans"
$strFailed_Input_Path = "e:\DECOS\DATA\barcode\failed\"
$strAtt_Filename      = $strFailed_Send_Path + "\failed_scans.txt"
　
####################
# Mailfunc variables
####################
$strSender_Mail_Address  = "Decos_Noreply@KPN.com"
$strReceipt_Mail_Address = "peter.harpe@kpn.com"
$strSMTP_Server          = "10.207.0.39"
$strBodyText             = "Geachte,`n`nBijgaand treft u een overzicht met bestanden in de \failed directory. `n`nMet vriendelijke groet,`nKPN Business Operations`nDCO Government"
　
########################
# Miscelaneous variables
########################
$strHostName             = hostname
$strAppRole              = facter application_role
$strAppName              = facter application_name
　
$bDebug                  = $False 
　
###################
# Logfile  
###################
# Compose logfile: $strLogBase$strDate$strLogExt 
#1) $strMyName will made equal to the scriptname, for example: Decosmail 
#2) after including $strLogBase log will be then: Decosmail- 
#3) after including $strDate    log will be then: Decosmail-22-03-2016   
#4) after including $strLogExt  log will be then: Decosmail-22-03-2016.log  
　
#Get filename of this script, the first part of the logfile will be made the equal to this. 
$strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a generic logfilename 
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
　
End-of-Job
#################################################################################################### 
# End script
####################################################################################################
