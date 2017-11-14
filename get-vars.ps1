##################################################################################################################################  
# Name        : get-vars.ps1 
# Purpose     : Get values from external cfg file in order to avoid usage of hard-coded values in the actual script
#
# Que?        : Include this script in het actual script
#               Make sure the "$cfg_file" exists containing the requered key's and value(s)
#
#               Call function ( here: get_mail ) in het actual script ( send_failed_scans.ps1 )
#               00001
#                ..
#               00317  $strSender_Mail_Address = get_mail "from"
#               00318  $strReceive_Mail        = get_mail "to"
#
#               This done by looping thru the \Decos\DATA\scansource\BARCODE\failed directory on a Decos fileserver.
#   
# By          : PH, 30-10-2017    
##################################################################################################################################
Function get_var
{
  Param ( [string] $cfg_key )

  $cfg_file="C:\management\Scripts\Pview5_Check\find_gwerr.cfg"

  if ( -Not ( Test-Path $cfg_file ))
  {
    echo "Error: config file $cfg_file does not exist !"
    exit
  }
 
  $retval=get-content $cfg_file | grep -v \# | grep "$cfg_key=" | cut -d '=' -f2  
  switch ($cfg_key)
  {
    from
    {  
      echo $retval
    }
    
    to
    {
      echo $retval
    }
 
    smtp
    {
      echo $retval
    }
    
    subject
    {
      echo $retval
    }   
    cc
    {
      echo $retval
    }    
    default
    {
      echo "-1000"
    } 
   }
 }   