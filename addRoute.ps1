<#############################################################################################
# Name        : addRoute.ps1
# Purpose     : add new route(s) using a dynamically determined default gateway
#               The default gateway that belongs to the destination address in var: $strDestination
#               is programmatically determined and selected
#               New IP addresses should be defined at the Init section in var: $strNewDestinations
#                                  and the corresponding NetworkMasks  in var: $strNewMasks
# Syntax      : ./addRoute.ps1
# Test        : C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -executi
#                                                  onpolicy bypass -file addRoute.ps1 
# 
# Parms       : none
# Dependancies: none
# Notes       : 
# Author      : PH
# Date        : 2016-06-06
#############################################################################################>
Set-PSDebug -Trace 0

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
#TND $SrvLst = @(SW44Z0005","SW44R0026","SW44R0025","SW44R0027","SW44R0100","SW44R0110","SW44R0111")
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
$Exec=0

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

  #-------------------- Begin standard code --------------------
  #Delete Share for logging
  DeleteShare
  #-------------------- End standard code --------------------

  Exit
}

##################################################################################################################
#                                                         Execute Script
##################################################################################################################
if ($Exec -eq 1)
{
  $bDebug     = $False
  
  $strLogHead = "==================================================================================================" 

  #TARGET IP who's default gateway should be determined and used
  # $strDestination="0.0.0.*"
  $strDestination="145.222.58.0"

  $strDestination_array=$strDestination -split '\.'
  #[0]0
  #[1]0
  #[2]0
  #[3]0
  # NEW DATA
  #Destination IP's to be added
  $strNewDestinations="145.222.96.0 145.222.242.0"
  # $strNewDestinations="145.222.242.0"
  $strNewDestinations_array = $strNewDestinations -split ' ' 

  #Corresponding NewWork MASK's to be added
  $strNewMasks="255.255.252.0 255.255.254.0"
  # $strNewMasks="255.255.254.0"

  $strNewMasks_array = $strNewMasks -split ' '

  #Compose logfile: $strLogBase$Date$strLogExt
  #1) $strMyName will made equal to the scriptname, for example: strReplace
  #2) after including $strLogBase log will be then: strReplace-
  #3) after including $Date       log will be then: strReplace-22-03-2016  
  #4) after including $strLogExt  log will be then: strReplace-22-03-2016.log 
 
  #Get filename of this script, the first part of the logfile will be made the equal to this.
  $strMyName   = $MyInvocation.MyCommand.Name.Split(".")[0] #Get filename of this script in order to compose a logfilename
  $strLogBase  = $strMyName + "-"
  $strLogExt   = ".log"

  #######################################################
  # Logfile (2)
  #######################################################
  $strLogFile ="B:\scripts\log\$strLogBase$Date$strLogExt"

  Write-Log $strLogHead
  Write-Log "Start run"
  Write-Log $strLogHead

  ################
  # Checks 
  ################
  #Windows 2003 ?
  if ( ! $OS.Contains($OSVer) )
  {
    Write-Log "This server is not equiped with Windows $OSVer" 
    End-Of-Job  
  }

  #Validity new data...
  #Same number of entries in both NewDestination and Default Gateway ?
  if ( $strNewDestinations_array.count -ne $strNewMasks_array.count )
  {  
    Write-Log "ERR: Number of Destination entries differs from number of Network mask entries"
    End-Of-Job
  }
  else
  {  
    # 4 octets in Destination IP ?
    for ( $index=0; $index -lt $strNewDestinations_array.count; $index++)
    {  
      $strNewDestination=$strNewDestinations_array[$index].ToString()
      $strNewDestination_array=$strNewDestination -split '\.'
      if ( $strNewDestination_array.count -ne 4 )
      {
        Write-Log "New destination: $strNewDestination is not a valid IP adress !"
        End-Of-Job
      }
    }

    # 4 octets in Subnet Mask ?
    for ( $index=0; $index -lt $strNewMasks_array.count; $index++)
    {    
      $strNewMask=$strNewMasks_array[$index].ToString()
      $strNewMask_array=$strNewMask -split '\.'
      if ( $strNewMask_array.count -ne 4 )
      {
        Write-Log "New mask: $strNewMask is not a valid Subnet Mask !"
        End-Of-Job
      }
    }
  }

  ##########
  # Run (3)
  ##########

  ########################
  # (3A) Get routing table
  ########################
  $strRoute=Get-WmiObject Win32_IP4RouteTable 
  #===========================================================================  
  #
  #IPv4 Route Table
  #===========================================================================
  #Active Routes:
  #Network Destination        Netmask          Gateway       Interface  Metric
  #     145.60.258.3          0.0.0.0      192.168.1.1     192.168.1.20    276
  #          0.0.0.0          0.0.0.0      144.44.56.1    144.44.56.166     25
  #        127.0.0.0        255.0.0.0         On-link         127.0.0.1    306

  ####################################################  
  # (3B) Loop thru routing table rows until 
  #      first 3 octets of the Network Destination IP 
  #                   -eq
  #      first 3 octets of variabele strDestination
  ####################################################
  foreach ( $strRoute_row in $strRoute )
  {
    $bFound=$True 
  
    $strRouteDestination=$strRoute_row.Destination
    #145.60.258.3

    $strRouteDestination_array = $strRouteDestination -split '\.' 
    #[0]145
    #[1]60
    #[2]258
    #[3]3
    #

    $strRouteDefaultGateway=$strRoute_row.NextHop
    #192.168.1.1

    # OK: Both destinations consists of 4 octets ( count=4 )
    if( $strRouteDestination_array.count -eq 4 -and $strDestination_array.count -eq 4)
    {
      # BUT: We only have to check the first 3 octets... (so we are not using the count property)
      for ( $index=0; $index -le 2; $index++)
      {
        if ( $bDebug -eq $True )
        {
  	      Write-Host $strDestination_array[$index] + "- " + $strRouteDestination_array[$index] 		
        }

        #[0]145 != [0]0 OR
        #[1]60  != [1]0 OR
        #[2]258 != [2]0 ?????? ==> No match here so $bFound = $False
        if ( $strDestination_array[$index] -ne $strRouteDestination_array[$index] )
        {
          $bFound = $False
        }     
      }

  	  if ( $bDebug -eq $true )
      {
	    echo " "
      }
	
      # We only need the first matching occurrence out of the routing table, 
      # if we have got it => escape from for loop
      if ( $bFound -eq $True )
      {
        break
      }	
    }  
  }  

  ##########################################
  # (3C) Loop done; default gateway found ?
  ##########################################
  if ( $bFound -eq $True )  
  {
    Write-Log "Default gateway: $strRouteDefaultGateway found with IP: $strRouteDestination"

    # (4D) OK, enter the add route loop
    for ( $index=0; $index -lt $strNewDestinations_array.count; $index++)
    {     
      if ( $bDebug -eq $true )
      {
        Write-Host "Adding: " $strNewDestinations_array[$index]  " with mask: " $strNewMasks_array[$index] " and DG: " $strRouteDefaultGateway
      }

      $log_record="Adding: " + $strNewDestinations_array[$index] + " with mask: " + $strNewMasks_array[$index] + " and DG: " + $strRouteDefaultGateway
      Write-Log $log_record

      Route add -p $strNewDestinations_array[$index] mask $strNewMasks_array[$index] $strRouteDefaultGateway
      # $rc=$LASTEXITCODE
      $rc=$?
      if ( $rc -ne $True )
      {
        Write-Log "ERR: something went wrong with adding new route !"
        End-of-Job 
      }
      else
      {
        Write-Log "OK: Route added succesfully"
      }    
    }  
  }
  else
  {
    Write-Log "No default gateway could be determined, target: $strDestination not found"
  }

  ##########
  # Exit (4)
  ##########
  End-of-Job
}
##################################################################################################################
#                                                        End Execute Script
##################################################################################################################
