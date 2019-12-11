############################################################################################  
# Name        : getafas.ps1
# Purpose     : get today's 'krm' csv file from Fides
# Syntax      : getafas.ps1 [APPL]
# Parm APPL   : AFS | ZEC | COL  
# Dependancies: none  
# 
# Log         : Logrecords from WinSCP and this script itself are written to 2 separate files 
#               Logfile cleaning is triggered by this script as well
#
# Notes       : All settings should be made in the Init (1) section 
# 
# 
# Author      : PH  
# Date        : 2019-11-15  
############################################################################################   

param(
   [string] $strApplication
)

if ( $strApplication -eq "" )
{
  Write-Host "No application parameter such as 'AFS' or 'ZEC' supplied !"
  Exit; 
}

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
   "$strHsName-$strDate-$strTime : $strLogData" >> $strScriptLog  
}  

function Cleanup-Log($strDir, $intDays) 
{ 
  $intFiles   = 0 
  $strPattern = "*.log" 
  $intAge     = (Get-Date).AddDays(-$intDays) 
  $strAge     = $intAge.Year.ToString() + "-" + $intAge.Month.ToString("0#") + "-" + $intAge.Day.ToString("0#") 
  Write-Log "Delete '$strPattern' files older than or equal to : $strAge" 
   
  $strScriptLogs = Get-Childitem $strDir -Include $strPattern -Recurse | Where {$_.CreationTime -le $intAge} 
  
  foreach ($strScriptLog in $strScriptLogs)  
  { 
    if ($strScriptLog -ne $NULL) 
    {         
      Write-Log "Deleting $strScriptLog" 
      Remove-Item $strScriptLog.FullName | out-null 
      $intFiles++ 
    }     
  } 
  return $intFiles 
} 

function CheckPath([string] $strCheckPath) 
{ 
  [Boolean] $bReturn=$False;

  if (  ( Test-Path $strCheckPath ) ) 
  { 
     $bReturn=$True;      
  } 
  return $bReturn;
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
 
##############################################################  
# Set Logfiles   
##############################################################  
#Compose logfile: $strLogBase$strDate$strLogExt  
#1) $strMyName will made equal to the scriptname, for example: AppendIP  
#2) after including $strLogBase log will be then: AppendIP-  
#3) after including $strDate    log will be then: AppendIP-22-03-2016    
#4) after including $strLogExt  log will be then: AppendIP-22-03-2016.log   
   
#Get filename of this script, the first part of the logfile will be made the equal to this.  
$strLogDir   = "C:\management\scripts\afas\Logs" 
$strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a logfilename  
$strLogBase  = $strMyName + "-" + $strDate  
$strLogExt   = ".log"  

#Script logging  
$strScriptLog = "$strLogDir\$strLogBase$strLogExt"  
#WinSCP logging
$strFTPLog    = "$strLogDir\WinSCP"+ "-" + $strDate+$strLogExt;
#Location of this script
$strScriptDir = "$PWD\$strMyName.error";

############################################################# 
# INIT
############################################################# 
#[Int]    $intPort = 22
#                    !76O5*Ja12NR$pqU
#[string] $strPrivate_key  = "C:\Users\Administrator\Documents\id_ibcc.ppk"

[String] $strEnvironment   = (facter customer_environment);
         $strEnvironment   = $strEnvironment.ToUpper();

[string] $strWinSCP        = "C:\WinSCP.lnk"

# Configuration files of all applications concerned
[Array]  $arAppl_Names     = @("AFS", "ZEC", "COL") 
[Array]  $arAppl_Confs     = @("afas_afs.cfg", "afas_zec.cfg", "afas_col.cfg")
[Int]    $intAppl_Index    = -1
[String] $strConfig_Path   = "C:\management\Scripts\Afas\"
[String] $strAppl_Config   = "";
[String] $strConfig_Key;
[String] $strConfig_Value;
[String] $strConfig_Split  = "?"; 

[String] $strConfig_Env    = "";
[String] $strConfig_Usr    = "";
[String] $strConfig_Psw    = "";
[String] $strConfig_Ldr    = "";
[String] $strConfig_Rdr    = "";
[String] $strConfig_Fnm    = "";

[String] $strRemoteHost    = "integratie.fidessolutions.nl"
[String] $strRemoteDir     = "AFS"

# [string] $strRemoteFile   = "krm_mdw_gegevensset_afs_TEST.csv"
[String] $strCommand      = '{0} /timeout=10 "/log={1}" /ini=nul /command "open sftp://{2}:{3}@{4} -hostkey=*" "lcd {5}" "cd {6}" "get {7}" "exit" ' -f`
                             $strWinSCP, $strFTPLog, $strUser, $strPass, $strRemoteHost, $strLocalPath, $strRemoteDir, $strRemoteFile

# Write-Host $strCommand

#############################################################
# Check if paths exist
#############################################################
if ( ! ( CheckPath $strLogDir ) )
{
  Write-Host "Logdirectory $strLogDir does not exist !" >> $strScriptDir;
  exit;  
}

##############################################################
# Start
##############################################################
# Cleanup old logfiles
# $intFiles=(Cleanup-log $strLogDir 62)
Write-Log "Number of deleted logfiles: $intFiles";

Start-of-Job 

# Does parameter match a known application ?
$intAppl_Index=$arAppl_Names.IndexOf( $strApplication );
if ( $intAppl_Index -lt 0 )
{
  Write-Log "Error: '$strApplication'  is not a valid application"
  End-of-Job
}
else
{
  Write-Log "Running a pickup job for '$strApplication' on $strEnvironment"  
}

# Check and load configuration(file)
$strAppl_Config = $strConfig_Path + $arAppl_Confs[$intAppl_Index];

if ( ! ( CheckPath $strAppl_Config ) )
{
  Write-Log "Configfile '$strAppl_Config'  does not exist !";
  End-of-Job; 
}

Write-Log "Ok: configfile '$strAppl_Config' found";
# Read configfile content
foreach( $strConfig_Rec in Get-Content $strAppl_Config ) 
{

  $strConfig_Key   = $strConfig_Rec.Split($strConfig_Split)[0].ToString().ToUpper();
  $strConfig_Value = $strConfig_Rec.Split($strConfig_Split)[1].ToString();

  switch($strConfig_Key)
  {
    ENV
    {      
      $strConfig_Env = $strConfig_Value;
    }

    USR
    {      
      $strConfig_Usr = $strConfig_Value;
    }

    PSW
    {
      $strConfig_Psw = $strConfig_Value;
    }
    
    RDR
    {
      $strConfig_Rdr = $strConfig_Value;
    }

    LDR
    {
      $strConfig_Ldr = $strConfig_Value;
    }

    FNM 
    {     
      $strConfig_FNM = $strConfig_Value;
    }

    default
    {
      Write-Log "$strConfig_Rec is an invalid configuration entry";
      End-of-Job;
    }
  }  
}

if ( $strConfig_Env -eq "" )
{
  Write-Log "No environment in config file";
  End-of-Job;
}

if ( $strConfig_Usr -eq "" )
{
  Write-Log "No FTP user found in config file";
  End-of-Job;
}
if ( $strConfig_Psw -eq "" )
{
  Write-Log "No FTP password found in config file";
  End-of-Job;
}
if ( $strConfig_Ldr -eq "" )
{
  Write-Log "No local directory found in config file";
  End-of-Job;
}

if ( $strConfig_Rdr -eq "" )
{
  Write-Log "No remote directory found in config file";
  End-of-Job;
}

if ( $strConfig_FNM -eq "" )
{
  Write-Log "No filename found in config file";
  End-of-Job;
}

Write-Log "Ok: all variables are found and loaded" 

if ( ! ( CheckPath $strWinSCP ) )
{
  Write-Log "WinSCP location $strWinSCP does not exist !";
  End-of-Job;
}

############################################################## 
# Main line 
############################################################## 
     
if ( ! ( CheckPath $strConfig_Ldr ) )
{
  Write-Log "Local destination directory '$strConfig_Ldr' does not exist !" 
  End-of-Job;
}  

$strCommand = '{0} /timeout=10 "/log={1}" /ini=nul /command "open sftp://{2}:{3}@{4} -hostkey=*" "lcd {5}" "cd {6}" "get {7}" "exit" ' -f`
                    $strWinSCP, $strFTPLog, $strConfig_Usr, $strConfig_Psw, $strRemoteHost, $strConfig_Ldr, $strConfig_Rdr, $strConfig_Fnm
  
# Write-Host $strCommand;

cmd.exe /c $strCommand
$bRc = $?
if ($bRc)
{
  Write-Log "$strRemoteFile $(get-date -format 'yyyy:MM:dd - hh:mm:ss') SUCCES"     
}
else
{
  Write-Log "$strRemoteFile $(get-date -format 'yyyy:MM:dd - hh:mm:ss') FAILED"
}

##############################################################
# End
##############################################################
End-of-Job