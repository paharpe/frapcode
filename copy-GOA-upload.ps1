# ---------------------------------------------------------------------------------------------------------------------------------------------
# Name    : copy-GOA-uploads.ps
#
# Purpose : Copy files from inputdirectory to the actual KIM-GOA's pick-up directory and archive these files after a succesfull copy
# 
# By      : Peter Harpe - 23 Jan 2018
#
# Changed : 20180125 (PH) Move to archive directory using the -force parameter. Existing files in ..\archive will now be overwritten
#           20180126 (PH) File in source_directory will always be copied to destination_directory ( regardless of whether they already exist ) 
# --------------------------------------------------------------------------------------------------------------------------------------------

#Include logfile cleanup code
. "C:\management\Scripts\KIM-GOA\cleanup-log.ps1"

Set-PSDebug -Trace 0

#-------------------- Begin standard code -------------------- 
$strHsName   = hostname 
$strDate     = Get-Date -format "yyyy-MM-dd" 
$strFullDate = Get-Date 
$strLogHead  = "=========================================================================================================="
#-------------------- End standard code --------------------

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

function copy-files([String] $strSourceDir, [String] $strDestDir, [String] $strArchDir )
{

  ###############
  # Exists ?
  ###############
  if ( Test-Path $strSourceDir )
  {
    # nop
  }
  else
  {
    Write-Log "Source directory $strSourceDir does not exist !"
    End-of-Job
  }
  if ( Test-Path $strDestDir )
  {
    # nop
  }
  else
  {
    Write-Log "Destination directory $strDestDir does not exist !"
    End-of-Job
  }
  if ( Test-Path $strArchDir )
  {
    # nop
  }
  else
  {
    Write-Log "Archive directory $strArchDir does not exist !"
    End-of-Job
  }
  # Select all files from inputfolder.
  # --------------------------------------------------------------------------------------------------------------------------------
  $sourcefiles = Get-ChildItem -Path $strSourceDir -Force | Where-Object { !$_.PSIsContainer }
  $filesnum=$sourcefiles.Count
  
  foreach ($sourcefile in $sourcefiles)
  {  
    #display
    Write-Log " "
    Write-Log "Copy $sourcefile" 

    if ( test-path $strDestDir\$sourcefile )
    {
      write-log "$strDestDir\$sourcefile already exists and will be overwritten !"
    } 
    else
    {   
      write-log "$strSourceDir\$sourcefile is new and will be copied"
    }
    
    #copy
    Copy-Item $strSourceDir\$sourcefile -Destination $strDestDir -Force
    if ( $? -eq $true )
    {
      Move-Item $strSourceDir\$sourcefile $strArchDir -Force
      if ( $? -eq $true )
      {
        write-log "$sourcefile succesfully copied and archived"
      }
      else
      {
        Write-log "An error occurred during archiving $sourcefile to $strArchDir"
      }
    }
    else
    {
      write-log "An error occurred during copying $sourcefile to $strDestDir"
    }   
  }
  Write-Log "Total number of copied files: $filesnum"
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

$strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a logfilename 
$strLogBase  = $strMyName + "-" + $strDate 
$strLogExt   = ".log"   
$strLogFile  = "$strLogDir\$strLogBase$strLogExt"
$strPattern  = "$strMyName*.log"
 
#PROD 
$strSourceDir = "D:\Uploads"
$strArchDir   = "D:\Uploads\Archive\"
$strDestDir   = "D:\Projects\Ombudsman_KIM_32\RuntimeData\Uploads"

#TEST
#$strSourceDir = "D:\PHIN"
#$strDestDir   = "D:\PHOUT"
#$strArchDir   = "D:\PHIN\ARCH\"


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

Write-Log "Start copying KIM-GOA files from $strSourceDir to $strDestDir"
Write-Log " "
copy-files $strSourceDir $strDestDir $strArchDir
Write-Log " "

End-of-Job