<#

.SYNOPSIS

The purpose of this script is to determine if there is enough disk space 
left on the unmanaged IAM appliances.

This is done by comparing the 3 parameter variables with
the actual values found in the data block with today's date in the file:
freespace.txt which is assigned by variable: $strInFile


.DESCRIPTION
Args:
-environment           test|acceptatie|productie
-warning               % after a warning will
-critical              % after when a critical will

.EXAMPLE
 INPUT: .\check_freespace.ps1 -env "productie" -warning 20 -critical 10
 OUTPUT: OK:      production [iamprdsp1:ok] [iamprdsp2:ok] [iamprdsp3:ok] [iamprdsp4:ok] [iamprdsp5:ok]
    -or-
         WARNING: production [iamprdsp1:ok] [iamprdsp2:warning] [iamprdsp3:ok] [iamprdsp4:ok] [iamprdsp5:ok]
    -or-
         CRITCAL: production [iamprdsp1:critical] [iamprdsp2:warning] [iamprdsp3:ok] [iamprdsp4:ok] [iamprdsp5:ok]

    So the most severe statuscode found int the 1..6 filesystems checked takes precedence and will be 
    used for the overall response

Created by:
P.A. Harpe, november 2018

Changelog:
2018-12-10: Because the preparation of freespace reports takes place from 00:00:00 to 01:00:00 daily, 
            a fixed "OK:"  message is returned during that period to avoid false positives. (PH)

#> 
[CmdletBinding()]
param(
    [string]$env,
    [int]$warning,
    [int]$critical
)

[String] $strEnvironment_Req=$env; 
# $strEnvironment_Req="productie"; 

[Int]$intWarning_if_LessThan=$warning;
# $intWarning_if_LessThan=20;


[int]$intCritical_if_LessThan=$critical;
#$intCritical_if_LessThan=10;



function set_status {
  param( [int]     $intExitRC,
         [string]  $strCenterity,
         [boolean] $bFinal)

  [string] $strNewBlock;
  if ( $intExitRC -eq $returnStateCritical )
  {
    $strNewBlock = ("[ $strHostPrevious : critical ]").Replace(" ","");
    $strCenterity = "$strCenterity $strNewBlock";
    if ( $bFinal )
    {
      $strCenterity="CRITICAL:$strCenterity";
    } 
    else
    {
     # NOP
    } 
  }
  else
  {
    if ( $intExitRC -eq $returnStateWarning )
    {
      $strNewBlock  = ("[ $strHostPrevious : warning ]").Replace(" ","");
      $strCenterity = "$strCenterity $strNewBlock";
      if ( $bFinal )
      {
        $strCenterity="WARNING:$strCenterity";
      }  
      else 
      { 
        # NOP;
      }
    }
    else
    {
      $strNewBlock = ("[ $strHostPrevious : ok ]").Replace(" ","");
      $strCenterity = "$strCenterity $strNewBlock";
      if ( $bFinal )
      {
        $strCenterity="OK:$strCenterity";
      }
      else
      { 
        # NOP;
      }
    }
  }
  return $strCenterity;
}


################################################################################################
# Init
################################################################################################
$returnStateOK = 0;
$returnStateWarning = 1;
$returnStateCritical = 2;
$returnStateUnknown = 3;

$intExitRC=$ReturnStateOK;
$strExitMSG="";

[int] $intCurrentHour=(Get-Date -UFormat "%H")

[String]     $strInFile="D:\Backups\CheckAppliance\freespace.txt";
# $strInFile="C:\users\Administrator\Desktop\freespace.txt";

[Boolean]    $bTodayFound = $false;
[Boolean]    $bEnvFound   = $false;
[String]     $strFreespace="FreeSpace:*";
[String[]]   $strEnvironment_In=("test","acceptatie","productie");
[String[]]   $strEnvironment_Out=("test","acceptance","production");
[String[][]] $strEnvironmentServer=(" ");
[String]     $strCurrentEnv="";
[string]     $strHost="";
[string]     $strHostPrevious="";
[String]     $strLine="";
[string]     $strFileSystems="";
[Int]        $intEnvIndex=-1;
[Int]        $intLineCount=0;
[Int]        $intServerCount=0;

[string]     $strCenterity="";

# Format: ma|di|wo|do|vr|za|zo
[String] $strWeekDay=(Get-Date -UFormat "%A").SubString(0,2);
# Format: 27-11-2018
[String] $strDDMMYYYY=Get-Date -UFormat "%d-%m-%Y";
# Format: di 27-11-2018
$strWDDDMMYYYY="$strWeekDay $strDDMMYYYY";

# $strWDDDMMYYYY="di 27-11-2018"

###################
# Check Environment
###################
if ( $strEnvironment_Req -notin $strEnvironment_In )
{
  Write-Host "UNKNOWN: environment '$strEnvironment_Req' is not defined !";
  exit $returnStateUnknown;
}

################################################################################################
# Mainline
################################################################################################
[String[]] $arLines=Get-Content -Path $strInFile;

foreach ( $strLine in $arLines)
{
  $strLine=$strLine.Trim();

  #############################################
  # TODAY'S DATE FOUND IN INPUTFILE ??
  #############################################
  if ( $bTodayFound )
  { 

    [Int]$intEnvIndex = [array]::IndexOf($strEnvironment_In, $strLine);
    
    ####################
    # Switch environment
    ####################
    if ( $intEnvIndex -ge 0 )
    {    
      if ( $strEnvironment_In[$intEnvIndex].ToString() -eq $strEnvironment_Req)
      {    
        $bEnvFound=$true;
        $strCurrentEnv=$strEnvironment_Out[$intEnvIndex];
        $strCenterity="$strCenterity $strCurrentEnv"
        $strCenterity=$strCenterity.Replace(" ","");
      }
      else
      {
        $bEnvFound=$false;
      }
    }
    
    #############################################
    # REQUESTED ENVIRONMENT REACHED ??
    #            AND 
    # AT THE DATA LINES  ??
    #############################################
    else
    {   
      if ($bEnvFound -and $strLine -like $strFreespace)
      {
         $strHost=$strLine | cut -d':' -f2 | cut -d'-' -f1;

         # Write-Host "New Host: $strHost"
         # Write-Host "Old Host: $strHostPrevious"

         ##############
         # AT HOSTBREAK
         ##############
         if ( ( $strHost -ne $strHostPrevious ) -and $strHostPrevious -ne "" -and $bEnvFound )
         {
           $strCenterity=set_status $intExitRC $strCenterity $false;               
         }
      
         $intExitRC=$returnStateOK;
         $strHostPrevious=$strHost;

        [string[]]$strarFileSystems=($strLine | cut -d' ' -f3-99).Split(" ");
                        
        foreach ( $strFileSystems in $strarFileSystems )
        {
          [string[]]$strarFileSystem=$strFileSystems.Split("-");
          [string]$strFileSystem = $strarFileSystem[0].ToString();
          [int]$intFreePct=100-$strarFileSystem[($strarFileSystem.Count-1)].ToString().Replace("%","");       
                     
          if ( $intFreePct -lt $intCritical_if_LessThan )
          {
            # Write-Host CRITICAL: $strarFileSystem[0].ToString()  $intFreePct 
            # $strCenterity="$strCenterity CRIT: $strFileSystem"
            $intExitRC=$returnStateCritical;
          }

          else
          {
            if ( $intFreePct -lt $intWarning_if_LessThan )
            {
              # Write-Host WARNING: $strarFileSystem[0].ToString()  $intFreePct
              # $strCenterity="$strCenterity WARN: $strFileSystem"
              if ( $intExitRC -eq $returnStateOK )
              { 
                $intExitRC=$returnStateWarning;
              }
            }
            else
            {
               # Write-Host OK: $strileSystem $intFreePct
            }
          }
        }       
      }
    }
    
    $intLineCount++;
	
    ###############################################
    # $bTodayFound=$false
    ###############################################
  }

  # Today's dateline reached ?
   if ( $strLine -eq $strWDDDMMYYYY )
  { 
    # set PROCESSING SWITCH to ON  
    $bTodayFound = $true;
  }
}

################################################################################################
# Exits
################################################################################################
# Between 00:00:00 and 01:00:00 all separate freespace reports are being collected and merged
# a static "OK" is returned during that periode to avoid false positives
if ( $intCurrentHour -ge 0 -and $intCurrentHour -le 1 )
{ 
  Write-Host "OK: freespace reports are being collected";
  exit $returnStateOK;  
}
if ( -not $bTodayFound )
{
  Write-Host "UNKNOWN: identifier '$strWDDDMMYYYY' could not be found in inputfile";
  exit $returnStateUnknown;
}

$strCenterity=set_status $intExitRC $strCenterity $true;

Write-Host $strCenterity;
Exit $intExitRC;