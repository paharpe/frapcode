

$strBase="C:\users\administrator\desktop"
$strDoPFX="$strBase\01.MakePFX.ps1"
$strDoListener="$strBase\02.Make_Listener.cmd"

if ( !( Test-Path "$strDoPFX" ))
{
  Write-Host "$strDoPFX does not exist !"
  exit
}
else
{
  & "$strDoPFX"
}


if ( !( Test-Path "$strDoListener" ))
{
  Write-Host "$strDoListener does not exist !"
  exit
}
else
{
  & "$strDoListener"
}


# erase "%BASE%\01.MakePFX.ps1"
# erase  %BASE%\02.Make_Listener.cmd
# REM erase "%BASE%\03.OpenFirewall.ps1"