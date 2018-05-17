$strHost=hostname
Write-Host "Determined hostname: $strHost"

############################################################################
# Funcions
############################################################################
function Check-File([string] $strFileid)
{
   
  if (!( Test-Path $strFileid ))
  {
    Write-Host "File $strFileid does not exist !"
    exit 
  }
  else
  {
    Write-Host "Ok: file $strFileid is present !"
  }
}

function TestOK([string]$strStep , [Boolean]$bOK )
{
  if ( $bOK -eq  $true )
  {
    Write-Host "Ok: $strStep succesfully"
 }
  else
{
    Write-Host "An error occurred while $strStep"
    exit
  }
}


############################################################################
# Init
############################################################################
$strKey="C:\ProgramData\PuppetLabs\puppet\etc\ssl\private_keys\$strHost.pem"
$strCert="C:\ProgramData\PuppetLabs\puppet\etc\ssl\certs\$strHost.pem"
$strPFX="c:\users\administrator\Desktop\$strHost.pfx"



############################################################################
# Check
############################################################################
Write-Host "Checking..."
Check-File $strKey
Check-File $strCert

############################################################################
# Run
############################################################################
[string] $strStep
[boolean] $bRC = $false

#Create PFX
#--------------------------------------------------------------------------------------------------------------------------------------
$strStep = "PFX creation"
& "C:\Program Files\Puppet Labs\Puppet\puppet\bin\openssl.exe " pkcs12 -inkey $strKey -in $strCert -export -out $strPFX -password pass:$strHost
$bRC=$?
TestOK $strStep $bRC


#Import PFX
#--------------------------------------------------------------------------------------------------------------------------------------
$strStep = "PFX import"
Start-Sleep 2
[System.Security.SecureString] $strPassword = ConvertTo-SecureString $strHost -AsPlainText -Force
Import-PfxCertificate -FilePath $strPFX Cert:\LocalMachine\My -Password $strPassword -OutVariable $strPfxOut
$bRC=$?
TestOK $strStep $bRC

#Firewallrule
#--------------------------------------------------------------------------------------------------------------------------------------
$strRuleName="Windows Remote Management (HTTPS-In)"
try {
    $fwrHTTPS = Get-NetFirewallRule -DisplayName $strRuleName -ErrorAction Stop
    Write-Host "Firewall rule already exist! "
}
catch
{
  if(-Not $fwrHTTPS)
  {
    #Open firewallport
    $strStep="Open Firewall"
    New-NetFirewallRule -DisplayName $strRuleName -Name $strRuleName -Profile Any -LocalPort 5986 -Protocol TCP
    $bRC=$?
    TestOK $strStep $bRC
  }
}