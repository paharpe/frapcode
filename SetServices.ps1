
#####################################################
# Doel  : Starten of stoppen services
#
# Parms : servicename action
#
# Syntax: ./SetServices.ps1 Neuron* OFF
#
# Door  : PH, 201902
#####################################################
[CmdletBinding()]
param(
    [string]$servicename,
    [string]$action
    )

[string] $strServiceName="$servicename*";
[string] $strAction=$action.toUpper();

if ( $strAction -ne "ON" -and $strAction -ne "OFF" )
{
  Write-Host "Action should contain 'ON' or 'OFF' !"
  Pause
  Exit
}

####################################################
# INIT 
####################################################

[string] $strForbidden_Service="Neuron Stelsel Registratie BAG Processor"


[string] $strStatus_off  = "Stopped"
[string] $strStartup_off = "Disabled"

[string] $strStatus_on  = "Running"
[string] $strStartup_on = "Automatic"

[string] $strStatus_old;
[string] $strStatup_old;

[string] $strStatus_new;
[string] $strStartup_new;

if ( $strAction -eq "ON" )
{
  $strStatus_old  = $strStatus_off;
  $strStartup_old = $strStartup_off;

  $strStatus_new  = $strStatus_on;
  $strStartup_new = $strStartup_on;
}

else
{
  $strStatus_old  = $strStatus_on;
  $strStartup_old = $strStartup_on;

  $strStatus_new  = $strStatus_off;
  $strStartup_new = $strStartup_off;
}


####################################################
# MAIN Line
####################################################

$strServices = Get-Service -DisplayName $strServiceName | Where-Object {$_.Status -eq $strStatus_old -and $_.StartType -eq $strStartup_old } | select -ExpandProperty name

if ( $strServices.Count -eq 0)
{
  Write-Host "No service(s) found with the specified name or status !";
  Pause
  Exit
}
else
{
  $YN = Read-Host $strServices.Count 'services found. Continue updating to status:' $strStatus_new '(Y/N)'
  If ( $YN -ne "y" -and $YN -ne "Y" )
  {
    Write-Host "No action!"
    Pause
    exit
  }
}

foreach ($strService in $strServices )
{   
  # Certain services may not be touched !!!
  if ( $strService -match $strForbidden_Service)
  {
    Write-Host
    Write-Host "$strForbidden_Service is ignored !"
    Pause   
  }

  else
  {
    Write-Host "------------------------------------------------------------------------------"
    Get-Service $strService

    if ( $strAction -eq "ON" )
    {
      Set-Service $strService -StartupType $strStartup_new;
      Set-Service $strService -Status $strStatus_new;
    }
    else
    {
      Set-Service $strService -Status $strStatus_new;
      Set-Service $strService -StartupType $strStartup_new; 
    }  

    Write-Host "New:"
    Get-Service $strService
  }
}
Write-Host
Write-Host "Ready!"
Pause