##################################################################################################################################  
# Name        : cursus-clean.ps1 
# Purpose     : Cleanup all files created since a specific date in order to have a clearn "Cursus" environment each day
#
#
# Syntax      : ./cursus-clean.ps1 
#
# Parms       : None
# Includes    : C:\management\Scripts\cursus-clean\cleanup-log.ps1 
#
# Notes       : All settings should be made/changed in the Init (1) section. 
# Author      : PH 
# Date        : 2018-03-02 
#################################################################################################################################  

Set-PSDebug -Trace 0 

. C:\management\Scripts\cursus-clean\cleanup-log.ps1

################################################################### 
# Functions 
###################################################################
 
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
  Write-Log "Run started" 
  Write-Log $strLogBar
}
 
function Write-Report-Head()
{
  $strDate=(Get-Date).ToString("yyyyMMdd")  
  $strTime=(Get-Date).ToString("HHmmss") 
  Write-Output $strLogBar                                                   >  $strAtt_Filename
  Write-Output "Start reporting Decos failed scans at $strDate / $strTime " >> $strAtt_Filename
  Write-Output $strLogBar                                                   >> $strAtt_Filename
}

 
######################## 
# Init
########################
$strBase_Path = "c:\management" 
$strBase_Date = "20180201"
$strTiff_Path = "E:\"

########################
# Miscelaneous variables
########################
$strHostName    = hostname
$intKeep        = 31
$strDate        = (Get-Date).ToString("yyyyMMdd") 
$strDescription = (Get-WmiObject -Class Win32_OperatingSystem |Select Description | cut -d'-' -f1 | tail -n3 | head -n1 ).Trim()
$bDebug         = $False
 
###################
# Logfile  
###################
# Compose logfile: $strLogBase$strDate$strLogExt 
#1) $strMyName will made equal to the scriptname, for example: Decosmail 
#2) after including $strLogBase log will be then: Decosmail- 
#3) after including $strDate    log will be then: Decosmail-22-03-2016   
#4) after including $strLogExt  log will be then: Decosmail-22-03-2016.log  
 
#Get filename of this script, the first part of the logfile will be made the equal to this. 
$strMyName  = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a generic logfilename 
$strLogDir  = $strBase_Path +"\log"
$strLogBase = $strMyName + "-" + (Get-Date).ToString("yyyyMMdd") 
$strLogExt  = ".log" 
$strLogFile = $strLogDir + "\$strLogBase$strLogExt" 
 

####################
# Makeup
#################### 
$strLogBar = "==========================================================================================================" 

#################################################################################################### 
# Run
#################################################################################################### 
Write-Log-Head
 
Write-Report-Head

Write-log " " 

Write-Log "** Start cleaning up old script logfiles **"
Cleanup-log $strLogDir $strMyName $intKeep
Write-Log "** End cleaning up old script logfiles **"
Write-Log " "

Write-Log "** Start cleaning up objects created during course **"
Write-Log "   Basedate: $strBase_Date"
Write-Log "   Basepath: $strTiff_Path"

$dtBase_Date= [DateTime]::parseExact($strBase_Date,"yyyymmdd", $null)
$intFiles   = 0

foreach ( $strFile in Get-Childitem $strTiff_Path -Recurse | Where {$_.CreationTime -gt $dtBase_Date} )
{   
    [string] $strFile_full = $strFile.FullName;
      
    # Write-Host $strFile_full
    Write-Log "Deleting: >> $strFile_full << "
    Remove-Item $strFile_full | out-null
    $intFiles++
     
}
Write-Log "Number of deleted files $intFiles";
Write-Log "** End cleaning up objects created during course **"

Write-Log " "
End-of-Job

#################################################################################################### 
# End script
####################################################################################################