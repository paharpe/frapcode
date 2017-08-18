############################################################################################ 
# Name        : Restart_Decos_JOIN_Services.ps1 
# Purpose     : Restart services having a name starting with "Decos JOIN"         
# Syntax      : ./Restart_Decos_JOIN_Services.ps1 
# Parms       : None 
# Dependancies: none 
#
# Log         : Logfile is named something like Restart_Decos-dd-mm-yyy.log 
#               31 versions are being maintained, older ones are cleaned
#               automatically 
# Notes       : All settings should be made in the Init (1) section 
# Author      : PH 
# Date        : 2017-08-14 
############################################################################################  

Set-PSDebug -Trace 0

#-------------------- Begin standard code -------------------- 
$strHsName   = hostname 
$strDate     = Get-Date -format "dd-MM-yyyy" 
$strFullDate = Get-Date 
$strLogHead  = "=========================================================================================================="
#-------------------- Einde standard code --------------------

################################################################## 
# Functions 
################################################################## 
function Write-Log([string]$strLogData) 
{ 
   $strDate=(Get-Date).ToString("yyyyMMdd")  
   $strTime=(Get-Date).ToString("HHmmss") 
   "$strHsName-$strDate-$strTime : $strLogData" >> $strLogFile 
} 

　
function RestartServices($strService2Restart)
{
    # Get all services where DisplayName matches $strService2Restart and loop through each of them.
    foreach($strServiceFound in (Get-Service -DisplayName $strService2Restart))
    {
        # Get name
        $strServiceFoundName = $strServiceFound.DisplayName
         
        # Get status before restart
        $strServiceFoundBefore = $strServiceFound.Status
        
        Write-Log "Status before: $strServiceFoundName is now $strServiceFoundBefore"
               
        # Restart service
        Restart-Service $strServiceFound

        # Get status after restart
        $strServiceFoundAfter = $strServiceFound.Status
        
        Write-Log "Status after: $strServiceFoundName is now $strServiceFoundAfter"
    }
}

function Cleanup-Log($strDir, $intDays)
{
  $intFiles   = 0
  $strPattern = "Restart_Decos*.log"
  $intAge     = (Get-Date).AddDays(-$intDays)
  $strAge     = $intAge.Year.ToString() + "-" + $intAge.Month.ToString("0#") + "-" + $intAge.Day.ToString("0#")

  Write-Log "Delete '$strPattern' files older than or equal to : $strAge"
  
  $strLogFiles = Get-Childitem $strDir -Include $strPattern -Recurse | Where {$_.CreationTime -le $intAge}
 
  foreach ($strLogFile in $strLogFiles) 
  {
    if ($strLogFile -ne $NULL)
    {        
      Write-Log "Deleting $strLogFile"
      Remove-Item $strLogFile.FullName | out-null
      $intFiles++
    }    
  }
  return $intFiles
}

function Start-of-Job()
{
  Write-Log $strLogHead
  Write-Log "Start run"
  Write-Log $strLogHead
}

function End-of-Job()
{
  Write-Log $strLogHead
  Write-Log "Run completed"
  Write-Log $strLogHead
  
  Exit
}

　
########## 
# Logfile  
########## 
#Compose logfile: $strLogBase$strDate$strLogExt 
#1) $strMyName will made equal to the scriptname, for example: AppendIP 
#2) after including $strLogBase log will be then: AppendIP- 
#3) after including $strDate       log will be then: AppendIP-22-03-2016   
#4) after including $strLogExt  log will be then: AppendIP-22-03-2016.log  
  
#Get filename of this script, the first part of the logfile will be made the equal to this. 
$strLogDir   = "C:\management\log"
$strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a logfilename 
$strLogBase  = $strMyName + "-" + $strDate 
$strLogExt   = ".log" 
  
$strLogFile ="$strLogDir\$strLogBase$strLogExt" 

　
#############################################################
# Main line
#############################################################
Start-of-Job

$intFiles=(Cleanup-log $strLogDir 31)
Write-Log "Number of deleted old logfiles: $intFiles"

RestartServices "Decos JOIN*"

End-of-Job 
