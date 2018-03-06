##################################################################################################################################  
# Name        : check_failedscans.ps1 
# Purpose     : Nagios/Centerity check: Counts failed scan TIF's on Decos fileserver
#
#               new:       number of TIF files arrived today
#               too large: number of todays TIF files > 15MB
#               old:       number of TIF files already reported and will be deleted next run ( names start with FAILED_ )
#               too large: number of yesterdays TIF files > 15MB
#
# Syntax      : ./check_failedscans.ps1 E:\Decos\Data\Scansource\BARCODE\FAILED
#
# Parms       : @path to failed scans
#
# Responses   : OK: no failed scans
#               OK: failed scans count new: 1( too large: 1) old:2 ( too large: 1)
#               No WARNINGS or CRITICALS will be issued, since these are just informative messages
#                
# Notes       : All settings should be made/changed in the Init (1) section. 
# Author      : PH 
# Date        : 2018-02-22 
#
# Changed     : 
##################################################################################################################################  
# Set-PSDebug -Trace 0


[CmdletBinding()]
param(
  [string]$strFailed_Input_Path
)

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#if ( $strFailed_Input_Path -eq $null -or $strFailed_Input_Path -eq "" )
#{
#$strFailed_Input_Path = "\\localhost\decosscan$\BARCODE\Failed\"
#}

###################################################################################################################################
# INIT
###################################################################################################################################

. C:\management\Scripts\SendFailedDecosScans\get-vars.ps1

########################
# Miscelaneous variables
########################
[string]  $strFailed        = "FAILED_"
[string]  $strExtension     = "tif"
[boolean] $bDebug           = $False 
[string]  $strReturnMessage = ""
[int]     $intReturnState   = 0; 

[int] $intMaxMB        = get_var "max"
[int] $intTooLarge_old = 0
[int] $intTooLarge_new = 0
[int] $intSizeOK_old   = 0
[int] $intSizeOk_new   = 0
[int] $intNew          = 0
[int] $intOld          = 0 

##################################################################################################################################
# MAIN
##################################################################################################################################
# For all *.tiff files:
$arrAllScans = Get-ChildItem -Path $strFailed_Input_Path | Where-Object { ( $_.Extension.ToUpper() | Select-String $strExtension.ToUpper() ) -and ! $_.PSIsContainer}
foreach ( $strScan in $arrAllScans )
{
  # Append full path to found tiff file and determine size
  [string] $strScanFull="$strFailed_Input_Path\$strScan"
  [int]    $intFailedSize=[math]::Round(((Get-Item "$strScanFull").length/1MB),2)
   
  # Tiff too large
  if ( $intFailedSize -gt $intMaxMB )
  {    
    # Already reported
    if ( $strScan.toString().Substring(0,7) -eq $strFailed )
    {
      $intTooLarge_old ++;
    }
  
    # Added today
    else
    {
      $intTooLarge_new ++;
    }  
  }

  # Not too large
  else
  {    
    if ( $strScan.toString().Substring(0,7) -eq $strFailed )
    {
      # Already reported
      $intSizeOk_old ++;
    }
  
    # Added today
    else
    {
      $intSizeOk_new ++;
    }  
  }

  # Counters
  $intNew = $intSizeOk_new + $intTooLarge_new;
  $intOld = $intSizeOK_old + $intTooLarge_old;
}                                                            

# Compose returnstring
if ( $intNew -gt 0 )
{
  $strFailedCount = "new: $intNew"
  if ( $intTooLarge_new -gt 0 )
  {
    $strFailedCount = "$strFailedCount(too large: $intTooLarge_new) "
  }
}

if ( $intOld -gt 0 )
{
  $strFailedCount = "$strFailedCount old: $intOld"
  if ( $intTooLarge_old -gt 0 )
  {
    $strFailedCount = "$strFailedCount(too large: $intTooLarge_old) "
  }
} 
 
if ( $intOld -eq 0 -and $intNew -eq 0 )
{ 
  $strReturnMessage = "OK: no failed scans"
  $intReturnState = $returnStateOK;
}
else
{
  $strReturnMessage = "INFO: failed scans count $strFailedCount"
  $intReturnState = $returnStateWarning;
}

####################################################################################################################################
# EOJ
####################################################################################################################################
   
write-host $strReturnMessage exit $returnStateOK