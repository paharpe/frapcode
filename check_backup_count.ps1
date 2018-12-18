<#

.SYNOPSIS

The purpose of this script is to determine whether the NUMBER OF FILES in a specific directory 
whose NAME starts with a SPECIFIC string AND are NOT EMPTY matches a specific required NUMBER

.DESCRIPTION
Args:
-filepath              Filepath
-number                required number of files

.EXAMPLE
.\backput_count.ps1 -filepath "D:\blah\backup*" -number 21

Created by:
P.A. Harpe, november 2018

Changelog:
2018-12-07: Because backup preparation and rotation takes place from 04:00:00 to 06:30:00 daily, 
            a fixed "OK:"  message is returned during that period. (PH)			
#> 
[CmdletBinding()]
param(
    [string]$path,
    [int]$number
)

$strFilePath=$path
$intNumber=$number

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

########################
# Init
########################
#$strFilePath=D:\Backups\AccessManagerAppliance\Acceptatie\iamsp1_*
#$intNumber=21

$intExitRC=$ReturnStateOK
$strExitMSG=""

[int] $intCurrentHour=(Get-Date -UFormat "%H")

if ( $strFilePath -eq "" )
{
  Write-Host "UNKNOWN: No file path supplied !"
  exit $returnStateUnknown
}
if ( -not ( Test-Path $strFilePath ))
{
  Write-Host "UNKNOWN: file path does not exist !"
  exit $returnStateUnknown
}

########################
# Main line
########################
$strBackupfiles = Get-ChildItem -Path $strFilePath | Where-Object { !$_.PSIsContainer -and $_.Length -gt 0  }
$intBackupfile_Count=$strBackupfiles.Count
  
#############################
# Exits  
#############################
# Because backups between 04:00:00 and 07:00:00 are made and rotated, the number of files in that period will vary.
# That's why in te meantime a (forced) OK messages will be returned.
if ( $intCurrentHour -ge 4 -and $intCurrentHour -le 6 )
{ 
  $strExitMSG="OK: the number of $strFilePath files matches the required number($intNumber)"
}
else
{
  if  ( $intBackupfile_Count -ne $intNumber )
  {
    # Write-Host "CRITICAL: 18 d:\blah\backup.zip files found while this should be 20" 
    $strExitMSG="CRITICAL: $intBackupfile_Count $strFilePath files found while this should be $intNumber" 
    $intExitRC=$returnStateCritical;
  }
  else
  {
    # Write-Host "OK: the number of d:\blah\backup.zip files matches the requited number(21)"
    if ( $strExitMSG -eq ""  )
    {
      $strExitMSG="OK: the number of $strFilePath files matches the required number($intNumber)"  
    }  
  }
}

Write-Host $strExitMSG;
exit $intExitRC;