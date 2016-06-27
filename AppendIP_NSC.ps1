#############################################################################################
# Name        : AppendIP_NCS.ps1
# Purpose     : Concatenate an extra string containing IP-addresses / subnet bits to 
#               an existing string that may only exist once in the file beeing changed       
# Syntax      : ./AppendIP_NCS.ps1
# Parms       : None
# Dependancies: none
# Files       : Inputfile is read and wil be renamed into inputfile-yyyymmdd-hhmmss
#             : Outputfile is renamed to the new inputfilename finaly
#             : Logfile is named something like AppendIP-dd-mm-yyy.log
# Notes       : All settings should be made in the Init (1) section
# Author      : PH
# Date        : 2016-06-01
############################################################################################# 
Set-PSDebug -Trace 0

$strFile2bChanged="C:\Management\Programs\Centerity Monitor Agent\NSC.ini"
$bRestart_service = $true  

#-------------------- Begin standard code --------------------
#Include FunctionsFile
. "C:\Management\Scripts\CU-Overheid\SupportFiles\FunctionFile.ps1" 

$HsName   = hostname
$Disc     = (Get-WmiObject -Class Win32_OperatingSystem).Description
$OS       = (Get-WmiObject -Class Win32_OperatingSystem).Caption
$Date     = Get-Date -format "dd-MM-yyyy"
$FullDate = Get-Date

#Create Share for logging
CreateShare

##########  Variables ##########
#Filter on servername: yes, no, When using multple server use comma "Server1"","Server2"
$SrvFlt = "yes"
#TND $SrvLst = @("SW44Z0005","SW44R0026","SW44R0025","SW44R0027","SW44R0100","SW44R0110","SW44R0111")
$SrvLst = @("SW44Z0005")
#ACC $SrvLst = @("SW44Z0004","SW44R0028","SW44R0033","SW44R0034","SW44R0035","SW44R0036","SW44R0037","SW44R0038","SW44R0039","SW44R0040","SW44R0055","SW44R0060","SW44R0068","SW44R0089","SW44R0117","SW44R0118","SW44R0119","SW44R0139","SW44R0099","SW44R0108","SW44R0109")
#PRD $SrvLst = @(SW44Z0003","SW44Z0006","SW44Z0008","SW44R0057","SW44R0012","SW44R0016","SW44R0017","SW44R0018","SW44R0019","SW44R0020","SW44R0021","SW44R0022","SW44R0023","SW44R0054","SW44R0061","SW44R0087","SW44R0090","SW44R0112","SW44R0113","SW44R0114","SW44R0115","SW44R0116","SW44R0138","SW44R0098","SW44R0104","SW44R0107")
$OSVer  = "2003"
  
#Application: All, AFS, Andreas, HIS, Kana, Key2B, MKS, SVP, TIM, Zylab
$App = "All"

#Environment: All, Ontwikkel, Test, Acceptatie, Productie
$Env = "Test"

#Include Filter
FilterFunction

#-------------------- Einde standard code --------------------
#During normal operation the exec variable is maintaned in FilterFuncion 
#$Exec=0

##################################################################
# Functions
##################################################################
function Write-Log([string]$strLogData)
{
  $strDate=(Get-Date).ToString("yyyyMMdd") 
  $strTime=(Get-Date).ToString("HHmmss")
  "$HsName-$strDate-$strTime : $strLogData" >> $strLogFile
}

function End-of-Job()
{
  Write-Log $strLogHead
  Write-Log "Run completed"
  Write-Log $strLogHead
  
  DeleteShare

  Exit
}

function Format-AppendString([string]$AppendIP)
{
  # String should look like this: ",'145.222.96.0/24', '145.222.97.0/24', '145.222.98.0/24' "
  # First we are going to get rid of all quotes, comma's and other stuff we do not need
  $AppendIP=$AppendIP.Replace("'","");
  $AppendIP=$AppendIP.Replace('"','');
  $AppendIP=$AppendIP -replace '\s+', ' '
  return $AppendIP
} 

Function Process-IP([string]$strIPM_in)
{
  ################################################################################################
  # Input: string $strIPN_in 
  # Valid contents for instance:
  #  : 192.168.1.1/24, 192.167.25.30/25
  #or: 192.168.1.1, 192.167.25.30
  #or: 192.168.1.1/24
  #or: 192.168.1.1
  # 
  # Output: Hashtable $Return{.OK}        {.IP}                       {.Mask} {.IPCount}
  #    Possible value(s)     True|False   192.168.1.1 192.167.25.30   24 25    2
  ################################################################################################

  [array]$arIP_out=@();
  [array]$arMask_out=@();
  [int]$intArrayIndex=0;

  [boolean]$bOK = $True

  if ( ! [bool]($strIPM_in -as [ipaddress]) )
  { 
    #Not a valid IP adress found yet, it might be a string with multiple IP's and/or
    #a subnet mask's. First, lets try to split on a comma.....
    [int]$intIndex=0
    $strIPM_in_array=$strIPM_in.split(",")
    foreach ( $strIPM_in_string in $strIPM_in_array )
    {     
      $strIPM_in_string = $strIPM_in_string.replace(" ","")      
      if ( [bool]($strIPM_in_string -as [ipaddress]) )
      {        
        $arIP_out+= @($strIPM_in_string) ;
        $arMask_out+= @("none");
        $intArrayIndex++;        
      }
      else
      {
        #Still not a valid IP adress found yet, it might be an subnet mask's issue,
        #assuming we are dealing with some kind of "192.168.1.1/24" format
        #So, split the string on "/" to determine if we get a valid IP in the
        #resulting [0] occurence 
        $strIPM_in_string_array=$strIPM_in_string.split("/")
        if ( [bool]($strIPM_in_string_array[0] -as [ipaddress]) )
        {          
          $arIP_out+= @($strIPM_in_string_array[0]) ; 
          $arMask_out+=@($strIPM_in_string_array[1]) ;        
          $intArrayIndex++; 
        } 
        else
        {
          Write-Log "ERR: $strIPM_in_string_array[0] is not a valid IP-address"
          $bOK=$False          
        }     
      }
      $intIndex++;
    }
  }  
  else
  {
    #Inputstring is a single valid IP address, without a mask
    $arIP_out+= @($strIPM_in);
    $arMask_out+= @("none");
    $intArrayIndex++;
  }
  

  [hashtable]$Return = @{}
  $Return.OK = $bOk
  $Return.IP = $arIP_out
  $Return.Mask = $arMask_out
  $Return.IPCount = $intArrayIndex

  return $Return
}

Function Build_Append_New([string] $strExist_IP, [string] $strNew_IP)
{
  ############################################################################################
  # Check for double entries and change those to NULL
  ############################################################################################ 
  [int]$intIndex=0;
  [int]$intOutputIndex=0;
  [int]$intInputInde=0;

  while ( $intIndex -lt $strExistingIPVals.IPCount )
  {
    $intIndex2 = 0;
    while ( $intIndex2 -lt $AppendIPingIPVals.IPCount)
    {
      if ( $strExistingIPVals.IP[$intIndex] -eq $AppendIPingIPVals.IP[$intIndex2])
      {
        #When double: change entry to NULL
        $AppendIPingIPVals.IP[$intIndex2] = $null
        $AppendIPingIPVals.Mask[$intIndex2] = $null
      }  
      $intIndex2++;
    }
    $intIndex++;
  }
  
  ##########################################################################################
  # Build new AppendIP duplicate values are removed
  ##########################################################################################
  [int]$intIndex=0
  [string]$AppendIP_new=""
  
  foreach ( $IP in $AppendIPingIPVals.IP )
  {
    if ( $IP -ne $null )
    {
      $AppendIP_new = $AppendIP_new + ", " + $IP+ "/"+$AppendIPingIPVals.Mask[$intIndex]
    }
    $intIndex++;
  }

  return $AppendIP_new;
}


################################################################################
# Begin of the actual processing starts here
################################################################################
if ($Exec -eq 1)
{

  ##########
  # Init (1)
  ##########
    
  $bDebug          = $False
  # $strPath         = "c:\Program Files\Centerity TESTBende"
  
  $strPath         = Split-Path $strFile2bChanged         # "C:\Management\Programs\Centerity Monitor Agent"
  $strFileName_In  = Split-Path $strFile2bChanged -Leaf   # "NSC.ini"
  $strFile_In      = "$strPath\$strFileName_In"
  
  $strFileName_Out = "output_file.txt"
  $strFile_Out     = "$strPath\$strFileName_Out"
  
  #Compose logfile: $strLogBase$Date$strLogExt
  #1) $strMyName will made equal to the scriptname, for example: AppendIP
  #2) after including $strLogBase log will be then: AppendIP-
  #3) after including $Date       log will be then: AppendIP-22-03-2016  
  #4) after including $strLogExt  log will be then: AppendIP-22-03-2016.log 
 
  #Get filename of this script, the first part of the logfile will be made the equal to this.
  $strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a logfilename
  $strLogBase  = $strMyName + "-" + $Date
  $strLogExt   = ".log"
  
  #Search for this value in the inputfile
  $strTarget       = "allowed_hosts="
  
  #  ////////////////////////////////////////////////////////////////
  #  TA - Toelichting bij change tbv Centerity upgrade.docx
  #  Windows
  #  De onderstaande bestanden moeten worden aangepast:
  #  •	Nsclient.ini
  #  •	Extrasettings.ini

  # De bestanden moeten aangevuld worden met de onderstaande netwerken:
  # 145.222.96.0/24
  # 145.222.97.0/24
  # 145.222.98.0/24
  # 145.222.99.0/24
  # 145.222.242.0/24
  # 145.222.243.0/24
  #  ////////////////////////////////////////////////////////////////

  #Append this value to the existing string (if found) in the inputfile
  $AppendIP       = "'145.222.96.0/24', '145.222.97.0/24', '145.222.98.0/24', '145.222.99.0/24', '145.222.242.0/24', '145.222.243.0/24'"
 
  #Makeup
  $strLogHead      = "=========================================================================================================="
  
  #######################################################################################################
  # Check (2)
  #######################################################################################################
  if ( -Not ( Test-Path $strPath ))
  {
    Write-Host "'"$strPath"' is not a valid path"
    DeleteShare
    Exit
  }
  
  ################
  # Checks Cntd...
  ################

  #Windows 2003 ?
  if ( ! $OS.Contains($OSVer) )
  {
    Write-Log "This server is not equiped with Windows $OSVer" 
    End-Of-Job  
  }
  
  
  #######################################################
  # Logfile (3)
  #######################################################
  #TEST 
  # $strLogFile = "$strPath\$strLogBase$intLogSeq$strLogExt"
  #PROD
  $strLogFile ="B:\scripts\log\$strLogBase$Date$strLogExt"
  
  ####################################################################################################
  # Run (4)
  ####################################################################################################
  Write-Log $strLogHead
  Write-Log "Start run"
  Write-Log $strLogHead
   
  ##########################
  # (4.A) Inputfile exists ?
  ##########################
  if ( -Not ( Test-Path $strFile_In ))
  {
    Write-Log "ERR: Inputfile $strFile_In not found !"
    End-of-Job
  }
  
  #####################################
  # (4.B) Target not found in inputfile
  #####################################
  $strResult=Select-String -Path $strFile_In -Pattern ^$strTarget
  if ( -Not $strResult )
  {
    Write-Log "ERR: Target $strTarget not found !"
    End-of-Job
  }
  else
  {
    # Due to strange behaviour ( the .count property does not have the value '1' in case of the target has been found once )
    # we have to fill the number variable ourselves...
    $number=$strResult.count
    
  
    ########################
    # (4.C) No unique target 
    ########################
    if ( $number -gt 1 ) 
    {
      Write-Log "ERR: More than 1 match found !"
      End-of-Job
    }
  
    else
    {
      #############################################################################
      # (4.D) OK: Single target found
      #
      # Split the string which has been found on ':' into separate variables as:
      # Input  : C:\blah\blih\blah.ini:3:Hello world!
      # Output : [0] C
      #          [1] \blah\blih\blah.ini
      #          [2] 3
      #          [3] allowed_hosts=192.168.1.1./24
      #
      # In this specific case we need the third occurrence....
      #############################################################################
      $strResult_array=$strResult -split ':'
      
      # Debug mode ?
      if ( $bDebug -eq $True )
      {
        $entries=0
        foreach ( $strResult_string in $strResult_array )
        { 
          "$entries  $strResult_string"
          $entries++
        } 
      }
      
      # Get Targets linenumber and stringvalue
      $intTargeted_line=$strResult_array[2]
      $strTargeted_string=$strResult_array[3]
  
      if ( $strResult_array[2] -eq $null -or $strResult_array[3] -eq $null )
      {
        Write-Log "ERR: At splitting strResult on : strResult_array[] does not have sufficient entries"
        End-of-Job
      }
      
      ######################################################################################
      # (4.E) Now, we are going to split $strTargeted_string
      #
      # allowed_hosts=192.168.1.1./24      on the "=" character to obtain the IP and mask:
      # as follows: 
      # [0]:allowed_hosts
      # [1]:192.168.1.1/24
      ######################################################################################
      $strTargeted_array=$strTargeted_string.split("=")
      $entries=0
      $strExistingIPMs=$strTargeted_array[1].toString()
      if ( $strExistingIPMs -eq $null )
      {
        Write-Log "ERR: variabele strExistingIPMs is null !"
        End-of-Job
      }
  
      ######################################################
      # (4.F) Check the format of the IP address
      #       {and subnet mask}
      # and split the input into separate array's
      # Where $strExistingIPVals is a hashtable containing
      # several values/array's
      ###################################################### 
      else
      {     
        $strExistingIPVals=(Process-IP $strExistingIPMs)
        
        if ( ! ( $strExistingIPVals.OK ))
        {
          Write-Log "ERR: one or more non-valid IP address found in: $strExistingIPMs "
          End-of-Job
        }       
      }
      ##########################################################################
      # (4.G) Check and (re)format the string containing all IP's en masks to be 
      #       appended
      ##########################################################################
      $AppendIP=(Format-AppendString $AppendIP)
  
      ######################################################
      # (4.H) Check the format of the IP address
      # {and subnet mask} and split the inputstring into 
      # separate array's.
      # Where $AppendIPingIPVals is a hashtable containing
      # several values/array's
      ######################################################  
      $AppendIPingIPVals=(Process-IP $AppendIP)
          
      if ( ! ( $AppendIPingIPVals.OK ))
      {
        Write-Log "ERR: AppendIP contains non-valid chars !"
        End-of-Job
      }
  
      ################################################################################
      # (4.I) Remove duplicates, and build new append string
      ################################################################################ 
      [string]$AppendIP_new=(Build_Append_New $strExistingIPVals $AppendIPingIPVals)
      if ( $AppendIP_new.Length -le 6 )
      {
        Write-Log "ERR: No valid Append string. No action !"
        End-of-Job
      }
  
  
      ####################################################################################################
      # (5) Replace string now
      ####################################################################################################
      $strReplace_string = $strTargeted_string + $AppendIP_new
      (Get-Content $strFile_In) -replace $strTargeted_string, $strReplace_string | Out-File $strFile_Out
      $rc=$?
      if ( $rc -eq $True )
      {
        Write-Log "OK: Line : $intTargeted_line value: $strTargeted_string has been changed"
        Write-Log "    Added: $AppendIP_new"
        
        ###################################################
        # (5.B) Rename original inputfile to a save version
        ###################################################
        $strDate=(Get-Date).ToString("yyyyMMdd") 
        $strTime=(Get-Date).ToString("HHmmss")
        $strFileName_In_Save = $strFileName_In + "-" +  $strDate + "_"+ $strTime
        
        Rename-Item $strFile_In $strFileName_In_Save
        $rc=$?
        if ( $rc -eq $True )
        {
          Write-Log "OK: Original inputfile: $strFile_In has been renamed to: $strFileName_In_Save"
          ##################################################################
          # (5.C) Rename file containing the change to the original filename
          ##################################################################
          Rename-Item $strFile_Out $strFile_In
          $rc=$?
          if ( $rc -eq $True )
          {          
            Write-Log "OK: Written outputfile: $strFile_Out has been renamed to: $strFileName_In"
            
            ##################################################################
            # (5.D) Restart Centerity Monitor Agent       IF DESIRED
            ##################################################################
            if ( $bRestart_service -eq $true )
            {    
              Write-Log "Attempting to restart $strService"         
              $strService="Centerity Monitor Agent"
              Restart-Service $strService -ErrorAction SilentlyContinue
              $rc=$?
              if ( $rc -eq $True )
              {
                Write-Log "OK: Succesfully restarted $strService service"
              }
              else  
              {
                Write-Log "ERR: Restart $strService service was unsuccesful !"
                End-of-Job
              }
            }
          }
          else
          {
            Write-Log "ERR: something went wrong with renaming the changed file into the original inputfilename!"
            End-of-Job
          }
        }
        else
        {
          Write-Log "ERR: something went wrong with renaming the original inputfile !"
          End-of-Job
        }
      }
      else
      {
        Write-Log "ERR: Something went wrong during the Get-Content -replace action !"
        End-of-Job
      }
    } 
  }
}  
