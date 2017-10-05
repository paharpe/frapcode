# --------------------------------------------------------------------------------------------------------------------------------
# Op de EBV share 
# \\sw444v1452\D:\DATA\EBV\common\import moeten bestanden verwijderd worden die ouder zijn dan een maand. 
#
# Hetzelfde geldt voor  de map \\swappdbi0001.basis.lan\overzichtnl\overzichtnl\JDD
# Zou handig zijn als dit voortaan elke dag gebeurt, dus bestanden ouder dan een maand verwijderen.
# --------------------------------------------------------------------------------------------------------------------------------
# Jan Wildenberg - 10 Juli 2017
#
# Gewijzigd: 2017-10-02 (PH)
# --------------------------------------------------------------------------------------------------------------------------------

. "C:\Users\pharpe\Documents\Adam\EBV-BINF\cleanup-log.ps1"

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
# Init  
########## 

#Compose logfile: $strLogBase$strDate$strLogExt 
#1) $strMyName will made equal to the scriptname, for example: delete-files-EBV 
#2) after including $strLogBase log will be then: delete-files-EBV- 
#3) after including $strDate       log will be then: delete-files-EBV-22-03-2016   
#4) after including $strLogExt  log will be then: delete-files-EBV-22-03-2016.log  
 
#Get filename of this script, the first part of the logfile will be made the equal to this. 
$strLogDir   = "C:\management\log"
$strLogDir =  "C:\Users\pharpe\Documents\Adam\EBV-BINF"

$strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a logfilename 
$strLogBase  = $strMyName + "-" + $strDate 
$strLogExt   = ".log"   
$strLogFile  = "$strLogDir\$strLogBase$strLogExt"
$strPattern  = "$strMyName*.log"
 
$dtLimit     = (Get-Date).AddDays(-30)

$strDataDir  = "D:\DATA\EBV\common\import"
$strDataDir  =  "C:\Users\pharpe\Documents\Adam\EBV-BINF\import"

##################
# Checks
##################

##############
# Logdirectory
##############
if ( Test-Path $strLogDir )
{
  # nop
}
else
{
  echo "Logdirectory $strLogDir does not exist !"
  exit
}
###############
# Datadirectory
###############
if ( Test-Path $strDataDir )
{
  # nop
}
else
{
  Write-Log "Data directory $strDatadir does not exist !"
  exit
}

##################
# Cleanup old logs
##################

Write-Log "Housekeeping: deleting old script logfiles"

$intFiles=(Cleanup-log $strLogDir $strPattern 31)

Write-Log "Done: Number of deleted old scriptlogfiles: $intFiles"

Write-Log " "

#############################################################
# Main line
#############################################################
Start-of-Job

Write-Log "Deleting EBV-BINF files older than: $dtLimit"

# Select files older than the $dtLimit.
# --------------------------------------------------------------------------------------------------------------------------------
$oldfiles = Get-ChildItem -Path $strDataDir -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $dtLimit }
$filesnum=$oldfiles.Count

foreach ($oldfile in $oldfiles)
{  
  #display
  Write-Log $oldfile -Name 

  #delete
  # $oldfile.Delete()
}

Write-Log "Total number of deleted files: $filesnum"

End-of-Job