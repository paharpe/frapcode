####################################################################################################
# Naam         : StUFZKNlogs.ps1
#
# Doel         : Aanmaken van een zipfile met daarin de Decos DVL StUFZKN Messagelogs(=tripleforms)
#                en/of StUFZKN Notificationlogs(=BWV vakantieverhuur) waar FB van de gemeente om 
#                heeft gevraagd. Deze files worden veelvuldig opgevraagd ten behoeve van debugging
#
# Output       : Zipfile                 ( Bijv: StUFZKN_B_20180215_09001600.zip )
#                Verwerkingsverslag      ( Bijv: StUFZKN_B_20180215_09001600.log )
#                                        namen worden dynamisch bepaald o.b.v.
#                                        de @type/@date/@timerange selectie die is gemaakt.
#
# Dependencies : C:\management\programs\zip.exe
#
# Aanleiding   : Herhaalde aanvragen van Functioneel Beheer amsterdam om deze logfiles 
#
# Flow         : M.b.v. een dialoogje worden een keuze gemaakt voor:
#                1) logfiletype in kwestie: T=Tripleforms, W=BWV, B=Beide
#                2) Datum
#                3) Tijdrange
#
#  De logfiles bevinden zich ( op dit moment ) in directorystructuren zoals onderstaande:
#  Tripleforms -> Decos: D:\DECOS\APPS\Integrations\StUFZKN\MessageLogs\Incoming\yyyy-mm-dd
#  Decos -> Tripleforms: D:\DECOS\APPS\Integrations\StUFZKN\MessageLogs\Outgoing\yyyy-mm-dd
#  Decos -> BWV          D:\DECOS\APPS\Integrations\StUFZKN\NotificationLogs\Outgoing\yyyy-mm-dd
#  BWV   -> Decos        D:\DECOS\APPS\Integrations\StUFZKN\NotificationLogs\Incoming\yyyy-mm-dd
#
#  Deze directories worden ( al naar gelang de gemaakte selectie ) doorlopen en bestanden waarvan
#  het timestamp in de gevraagde range valt, worden gekopieerd naar de zipfile.
#
#
# Door      : PH, 2018-02-15
#
# Gewijzigd : Gebleken is dat LastWriteTime een ander timestamp format verwacht dan aanvankelijk
#             aangenomen: ( MM/DD/YYYY HH:MM:SS ). Dit is opgelost door de string 
#             $strSelectionDate te introduceren. ( PH, 19-02-2018 )
# 
#             Daarna is tevens naar voren gekomen dat de verwerking behoorlijk lang kan duren:
#             ruim 8 minuten voor 2x 2000 files Messagelogs      (Incoming en Outgoing)
#                              +  2x   57 files Notificationlogs (Incoming en Outgoing)
################################################################################################

################################################################################################
# Includes
################################################################################################
. C:\management\Scripts\StUFZKNlogs\genpass.ps1

################################################################################################
# Functions
################################################################################################
############################################################
Function clCheckPath([string] $strCheckPath)
############################################################
{
  if ( ! ( Test-Path $strCheckPath ) )
  {
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    $MessageBody = "$strCheckPath does not exist ! `n`n Script will exit !"
    $MessageTitle = "Error $strMyName"
 
    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon) 
    
    exit -1 
  }
}

##########################################################
function ask-type()
##########################################################
{
  [string] $strStufType =$null
  while ( $strStufType -ne "T" -and $strStufType -ne "W" -and $strStufType -ne "B"  )
  { 
    $strStufType = Read-Host "T=Tripleforms, W=BWV or B=Both ? ( or . to exit )"
    $strStufType=$strStufType.ToUpper();
    if ( $strStufType -eq "." )
    {
      exit;
    }
  }
  return $strStufType;
}

#########################################################
function ask-date()
#########################################################
{
  [string]  $strDate = $null
  [boolean] $bDateOK = $False
  while ( !$bDateOK )
  { 
    [string] $strDate = Read-Host "Date YYYYMMDD ? ( or . to exit )"
    if ( $strDate -eq "." )
    { 
      exit;
    }
    
    #Length
    if ( $strDate.Length -eq 8 )
    {
      #Write-Host "Date length OK"
      
      #Isolate and check year
      [string] $strYear = $strDate.Substring(0,4);
      if ($strYear -ge 2018 -and $strYear -le 2099 )
      {
        #Write-Host "Year value OK"
       
        #Isolate and check month
        [string] $strMonth = $strDate.Substring(4,2);
        if ($strMonth -ge "01" -and $strMonth -le "12" )
        {
          #Write-Host "Month value OK"
         
          #Isolate and check Day
          [string] $strDay = $strDate.Substring(6,2);
          if ($strDay -ge "01" -and $strMonth -le "31" )
          {
            #Write-Host "Day value OK"

            $strDate = $strYear + "-" + $strMonth + "-" + $strDay
            $strSelectionDate= $strMonth + "/" + $strDay + "/" + $strYear
            $bDateOK=$True;
          }
          else
          {
            Write-host "Invalid value for Day"
          }
        }
        else
        {
          Write-host "Invalid value for Month"
        }
      }
      else
      {
        Write-host "Invalid value for Year"
      }     
    }
    else
    {
      write-host "Invalid date format"
    }    
  }
  # Will return a value like: 2018-02-14@02/14/2018
  # to be splitted into 2 separate vars: 2018-02-14 
  #                             and    : 02/14/2018
  # Need them both 
  return "$strDate@$strSelectionDate";
  
  #return $strDate;
}

#########################################################
function ask-time()
#########################################################
{
  [string]  $strTime = $null
  [boolean] $bTimeOK = $False
  while ( !$bTimeOK )
  { 
    [string] $strTime = Read-Host "Time range HHMM-HHMM ? ( or . to exit )"
    if ( $strTime -eq "." )
    { 
      exit;
    }
    
    #Length
    if ( $strTime.Length -eq 9 )
    {
      #Write-Host "Time length OK"   
      
      #Isolate starthour
      [string] $strHour_start = $strtime.Substring(0,2);  
      if ( $strHour_start -ge "00" -AND $strHour_start -le "23" )
      {
        #write-host "Hour_start value OK"
        
        #Isolate startminute
        [string] $strMinute_start = $strtime.Substring(2,2);  
        if ( $strMinute_start -ge "00" -AND $strMinute_start -le "59" )
        {
          # write-host "Minute_start value OK"
         
          #Isolate separator
          [string] $strSep  = $strtime.Substring(4,1);  
          if ( $strSep -eq "-" )
          {
            # write-host "Separator value OK"
            
            #Isolate endhour
            [string] $strHour_end = $strtime.Substring(5,2);  
            if ( $strHour_end -ge "00" -AND $strHour_end -le "23" )
            {
              # write-host "Hour_end value OK"
              
              #Isolate endminute
              [string] $strMinute_end = $strtime.Substring(7,2);  
              if ( $strMinute_end -ge "00" -AND $strMinute_end -le "59" )
              {
                # write-host "Minute_end value OK"
                $strTime_start=$strHour_start+$strMinute_start;
                $strTime_end=$strHour_end+$strMinute_end;

                if ( $strTime_start -gt $strTime_end )
                {
                  Write-Host "Startime should not be greater than endtime !"
                }
                else
                {
                  #Insert ":" 
                  $strTime_start=$strHour_start + ":" + $strMinute_start;
                  $strTime_end=$strHour_end + ":" + $strMinute_end;

                  $strTime = $strTime_start + "-" + $strTime_end;
                  
                  $bTimeOK=$true;
                }
              } 
            }
          }
        }
      }
    }
    else
    {
      write-host "Invalid time format"
    }     
  }
  return $strTime;
}

##########################################################
function ask-pass()
##########################################################
{
  [string] $strZipPass=$null
  while ( $strZipPass -ne "Y" -and $strZipPass -ne "N"   )
  { 
    $strZipPass = Read-Host "Protect zipfile using generated password Y/N ? ( use . to exit )"
    $strZipPass=$strZipPass.ToUpper();
    if ( $strZipPass -eq "." )
    {
      exit;
    }
  }
  return $strZipPass;
}

#######################################################
function zip-logs([string] $strSourcePath )
#######################################################
{
  [string] $strStUFZKNCopy
  [string] $strStUFZKNZip    = $strDestPath + "\" + $strDestZipFile
  [string] $strStUFZKNReport = $strDestPath + "\" + $strDestLogFile

  Write-Host "Writing zipfile: $strStUFZKNZip"
   
  [integer]$intStUFZKNCount=0;
    
  $strStUFZKNLogs=(Get-ChildItem $strSourcePath | where {$_.LastWriteTime -gt $strTime_start -and $_.LastWriteTime -le $strTime_end })
    

  foreach ( $strStUFZKNLog in $strStUFZKNLogs )
  {

    $strStUFZKNCopy = $strSourcePath + "\" + $strStUFZKNLog

    if ( test-path $strZipper) 
    {
      # No password used
      if ( $strPassword -eq $null )
      {
        zip $strStUFZKNZip $strStUFZKNCopy >> $strStUFZKNReport
      }
      # Use password
      else
      {
        zip $strStUFZKNZip $strStUFZKNCopy -P $strPassword >> $strStUFZKNReport       
      }
    }
    else
    {
      write-host "Zipper ($strZipper) not present !"
    }

    $intStUFZKNCount++;
  }
  write-host "Done: $intStUFZKNCount files found and written"
  write-host "" 
}

#########################################################
Function get-Fromtripleform-logs()
#########################################################
{
  [string] $strSourcePath = $strFromTripelePath + "\" + $strDate;
  write-host ""  
  Write-Host "Start selection on Tripleforms FROM logging"
   
  if ( Test-Path $strSourcePath )
  {
    write-host "OK: logdirectory $strSourcePath exists"
          
    zip-logs $strSourcePath    
  }
  else
  {
    write-host "ERROR: logdirectory $strSourcePath does NOT exist !"
  }
}

#########################################################
Function get-Totripleform-logs()
#########################################################
{
  [string] $strSourcePath = $strToTripelePath + "\" + $strDate;
  Write-Host "" 
  Write-Host "Start selection on Tripleforms TO logging"
   
  if ( Test-Path $strSourcePath )
  {
    write-host "OK: logdirectory $strSourcePath exists" 
    
    zip-logs $strSourcePath    
  }
  else
  {
    write-host "ERROR: logdirectory $strSourcePath does NOT exist !"
  }
}

#########################################################
Function get-tobwv-logs()
#########################################################
{
  [string] $strSourcePath = $strtoBWVPath + "\" + $strDate;
  Write-Host ""
  Write-Host "Start selection on BWV TO logging"
   
  if ( Test-Path $strSourcePath )
  {
    write-host "OK: logdirectory $strSourcePath exists"
       
    zip-logs $strSourcePath    
  }
  else
  {
    write-host "ERROR: logdirectory $strSourcePath does NOT exist !"
  }
}

#########################################################
Function get-frombwv-logs()
#########################################################
{
  [string] $strSourcePath = $strfromBWVPath + "\" + $strDate;
  Write-Host ""
  Write-Host "Start selection on BWV FROM logging"
   
  if ( Test-Path $strSourcePath )
  {
    write-host "OK: logdirectory $strSourcePath exist"
       
    zip-logs $strSourcePath    
  }
  else
  {
    write-host "ERROR: logdirectory $strSourcePath does NOT exist !"
  }
}

################################################
Function remove-bad-chars([string] $strStringIN)
################################################
{
  $strStringIN=$strStringIN.Replace(":","");
  $strStringIN=$strStringIN.Replace("-","");
  $strStringIN=$strStringIN.Replace("/","");  
  return $strStringIN
}




#################################################################################################
# Init
#################################################################################################
[boolean] $bDebug            = $true

[string]  $strHsName         = hostname
[string]  $strMyName         = $MyInvocation.MyCommand.Name.Split(".")[0] 

[string] $strBasePath        = "D:\DECOS"
[string] $strStufZkPath      = $strBasePath + "\APPS\Integrations\StUFZKN"
[string] $strFromTripelePath = $strStufZkPath + "\MessageLogs\incoming"
[string] $strToTripelePath   = $strStufZkPath + "\MessageLogs\outgoing"
[string] $strToBWVPath       = $strStufZkPath + "\NotificationLogs\outgoing"
[string] $strFromBWVPath     = $strStufZkPath + "\NotificationLogs\incoming"

[string] $strDestPath        = "C:\Users\Administrator\Downloads"
[string] $strZipper          = "C:\Management\Programs\Utils\zip.EXE"

#################################################################################################
# Checks
#################################################################################################
clCheckPath $strBasePath
clCheckPath $strStufZkPath
clCheckPath $strFromTripelePath
clCheckPath $strToTripelePath
clCheckPath $strToBWVPath
clCheckPath $strFromBWVPath


##################################################################################################
# Mainline
##################################################################################################
while ( $true )
{

  # 1. Ask for the required logfile type
  [string] $strType          = ask-type  
  # 2. What date ?
  [string] $strDates         = ask-date
  [string] $strDate          = $strDates.Substring(0,10)
  [string] $strSelectionDate = $strDates.Substring(11,10)
  # 3. What timeframe ?
  [string] $strTime          = ask-time
  # 4. Use Password ?
  [string] $strPass          = ask-pass
  
  # Set timestamp vars
  # Must look like "02/14/2018 23:30:00" to represent 14 february 2018 half past 11 PM
  [string] $strTime_start  = $strSelectionDate + " " + $strTime.Substring(0,5) + ":00";
  [string] $strTime_end    = $strSelectionDate + " " + $strtime.Substring(6,5) + ":00";
  # Set zipfile name
  [string] $strDestZipFile = remove-bad-chars ( "StUFZKN_" + $strType + "_" + $strDate + "_" +  $strTime + ".zip" )
  # Set logfile name
  [string] $strDestLogFile = remove-bad-chars ( "StUFZKN_" + $strType + "_" + $strDate + "_" +  $strTime + ".log" )
  
  [string] $strPassword    = $null

  # Confirm ?
  write-host "Search for $strType logs on: $strDate between: $strTime_start and: $strTime_end "
  if ( $strPass -eq "Y" )
  {
     # Generate a password right now
     $strPassword = get-pass
     write-host "and protect the zipfile with a password $strPassword"
  }
  
  [string] $strYN=read-host "Is this correct ? (Y/N)   ( use . to exit )"
  if ( $strYN -eq "." )
  {
    exit;
  }

  if ( $strYN.ToUpper() -eq "y".ToUpper() )
  {
    break;
  }  
}

Write-host "Start, " (Get-Date)

if ( $strType -eq "B" -or $strType -eq "T" )
{
  get-fromtripleform-logs 

  get-totripleform-logs  
} 

if ( $strType -eq "B" -or $strType -eq "W" )
{
  get-tobwv-logs
  
  get-frombwv-logs 
}

# Add some passwordinfo to reportfile
[string] $strStUFZKNReport = $strDestPath + "\" + $strDestLogFile
" "                      | Add-Content $strStUFZKNReport
"Password: $strPassword" | Add-Content $strStUFZKNReport


Write-host "Done, " (Get-Date)

write-host "Press <Enter> to exit"
read-host
exit              