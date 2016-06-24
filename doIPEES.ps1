#############################################################################################
# Name        : doIPEES.ps1
# Purpose     : Execute a script against inputfiles specified in @arProcess_files  
# Syntax      : ./doIPEES
# Parms       : none 
# Dependancies: ./AppendIP.ps1
# Author      : PH
# Date        : 2016-06-24
############################################################################################# 
Set-PSDebug -Trace 0

$strCommand="AppendIP.ps1"

if ( -Not ( Test-Path $strCommand ))
{
    Write-Host "ERR: Script: $strCommand not found !"
    Exit
}

  
[array]$arProcess_files=@("'C:\Management\Programs\Centerity Monitor Agent\NSC.ini'","'C:\Management\Programs\Centerity Monitor Agent\Custom\extra_settings.ini'")

foreach ( $strProcess_file in $arProcess_files )
{ 
  Write-Host "Processing: $strProcess_file"
  Invoke-Expression "./$strCommand $strProcess_file"  
  $rc=$?
  if ( $rc -ne $true )
  {
    Write-Host "ERR: Execution of #strCommand agains $strProcess_file was unsuccessful !"
    break
  }     
}
 
