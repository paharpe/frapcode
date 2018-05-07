 ##############################################################################################################
 # Name  : Restart_Stopped_Service.ps1
 # Purp  : Once scheduled this script will restart every non-running service as they are 
 #         stored in the inputfile.
 # Parms : @Path\@textfile_containing_services 
 # Log   : C:\management\log\Restart_Stopped_Service.log
 #
 # Syntax: .\Start_Decos_XMLimport_Service.ps1 @Path\@textfile_containing_services"
 # Bijv  : .\Start_Decos_XMLimport_Service.ps1 C:\Management\scripts\services.txt
 #
 # PH, 2018-05-03
 ############################################################################################################## 

 Param(
 [Parameter(Mandatory=$True)]
 [ValidateNotNull()]
 [string]$strServiceFile
 )

 ################################################
 # Functions
 ################################################
 Function HandleService([string]$strService)
 {
   
   ################################################
   # Init
   ################################################
   $strSMTP    = "smtp-hent.acc.amsterdam.nl"
   # $strTo      = "cuoverheid@kpn.com"
   $strTo	   = "peter.harpe@kpn.com"
   # $strService = "Decos Document XML Import Service"

   ################################################
   # Processing
   ################################################
   if (Get-Service -Name $strService -ErrorAction SilentlyContinue )
   {
     $arrService = Get-Service -Name $strService -ErrorAction SilentlyContinue
     if ($arrService.Status -ne "Running")
     {
       Try  
       {
       
         Write-Host "Starting $strService service..." 
         Start-Service $strService -ErrorAction Stop
         $result = if (($_ | get-service).Status -eq "Running") {"success"} else {"failure"}
       }
       Catch
       {
         $result = "a catastrophic failure"
       }

       Finally
       {
         $strResult = "Service '$strService' stopped unexpectedly and has been restarted with $result."
    
         Write-Host -ForegroundColor Red "$strResult"

         # Compose Message
         $objMsg  = new-object Net.Mail.MailMessage
         $objSMTP = new-object Net.Mail.SmtpClient($strSMTP)
     
         # Is: sw444___.hent.lan
         $strFrom=  facter "fqdn"

         # Wordt: sw444___@hent.lan
         $strFrom=$strFrom.Replace(".hent","@hent")
     
         # sw444___.hent2.lan
         if ( ! $strFrom.Contains("@") )
         {      
           # Of anders: sw444___.hent2@hent.lan
           $strFrom="$strFrom@hent.lan"
         }
         $objMsg.From = $strFrom
       
         $objMsg.To.Add($strTo)
         $objMsg.from    = "sw444v1421@hent-t.tst"
         $objMsg.Subject = $strService
         $objMsg.Body    = $strResult
     
         # And send it
         $objSMTP.Send($objMsg)
      }
    }
    else
    { 
      Write-Host -ForegroundColor Green "$strService service is already started"  
    }
  }
  else
  {
    Write-Host -ForegroundColor Red "$strService service not found"  
    "$strService service not found" >> $strLogFile
  }
}

################################################
# INIT
################################################
$strLogFile="C:\management\log\Restart_Stopped_Service.log"

################################################
# Check
################################################
if ( -Not ( Test-Path $strServiceFile ))
{ 
  Write-Host -ForegroundColor Red "'$strServiceFile' does not exist !"
  "'$strServiceFile' does not exist !" >> $strLogFile
  exit 
}  

$strServices=get-content $strServiceFile
ForEach ($strService in $strServices)
{
  HandleService $strService
}  

Exit