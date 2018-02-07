 Set-PSDebug -Trace 0 

. C:\management\Scripts\CleanUp_Cursus\cleanup-log.ps1
. C:\management\Scripts\CleanUp_Cursus\get-vars.ps1
 
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
 

function CleanUp-Cursus([datetime] $dtBaseDate, [string] $strCursusPath)
{
  $intFiles=0
  Get-Childitem $strCursusPath -Recurse | Where {$_.CreationTime -gt $dtBaseDate} | % {
    Write-Host $_.FullName
    ### Remove-Item $_.FullName
    $intFiles++
  }
  
  Write-Log "   - Done. $intFiles files found."  
}

　
#################### 
# Init (1) 
####################
 
####################
# Makeup
#################### 
$strLogBar               = "==========================================================================================================" 
 
####################
# Paths
####################
$strBase_Path            = "c:\management"
$strCursus_CleanUp_Path  = $strBase_Path +"\scripts\CleanUp_Cursus"
# $strCursus_CleanUp_Path = "e:\DECOS\DATA\scansource\BARCODE\Failed\"

########################
# Miscelaneous variables
########################
$strHostName             = hostname
$intKeep                 = 31
$strDate                 = (Get-Date).ToString("yyyyMMdd") 
$strDescription          = (Get-WmiObject -Class Win32_OperatingSystem |Select Description | cut -d'-' -f1 | tail -n3 | head -n1 ).Trim()
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
$strLogDir   = $strBase_Path +"\log"
$strLogBase  = $strMyName + "-" + (Get-Date).ToString("yyyyMMdd") 
$strLogExt   = ".log" 
$strLogFile  = $strLogDir + "\$strLogBase$strLogExt" 

##################
# Selection
##################
$dtBaseDate  = [DateTime]::parseExact("20180101","yyyymmdd", $null)
$strDataDir  = "E:\Decos\Data\"
 
#################################################################################################### 
# Run
#################################################################################################### 
Write-Log-Head
 
Write-Report-Head

Write-Log "** Start cleaning up old logfiles **"
Cleanup-log $strLogDir $strMyName $intKeep
Write-Log "** End cleaning up old logfiles **"
Write-Log " "

Write-Log "** Start cleaning up old cursusfiles **"
Write-Log "   - Basedate: $dtBaseDate "
Write-Log "   - Datadir : $strDataDir "
CleanUp-Cursus $dtBaseDate $strDataDir 
Write-Log "** End cleaning up old cursusfiles **"
Write Log " "

　
End-of-Job

#################################################################################################### 
# End script
#################################################################################################### 
