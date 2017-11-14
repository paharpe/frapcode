##############################################################
# Code to be included, should be used to cleanup old logfiles
# Parms: 1 logdirectory   z.b.: C:\management\logs
#        2 pattern        z.b.: Restart_log*.log
#        3 number of days z.b.: 31
#
# PH, 2017-10-05
##############################################################
function Cleanup-Log($strDir, $strPattern, $intDays)
{
  # Check if logdirectory exists
  if ( Test-Path $strDir ) 
  {
    # Nop
  }
  else
  {
    echo "Parm path $strDir doest not exist !"
    exit
  }

  # Check if filepattern is given
  if ( $strPattern -eq "" )
  {
    echo "File pattern is empty !"
    exit
  }

  # And finaly: are the number of days correctly passed ?
  if ( $intDays -is [int] )
  {
    if ( $intDays -gt 0 )
    {
      # nop
    } 
    else
    {
      echo "Age in days should be greater than 0 !"
      exit
    }
    # nop
  }
  else
  {
    echo "Age in days should be an integer value !"
    exit
  }


  $intFiles   = 0
  $intAge     = (Get-Date).AddDays(-$intDays)
  $strAge     = $intAge.Year.ToString() + "-" + $intAge.Month.ToString("0#") + "-" + $intAge.Day.ToString("0#")

  Write-Log "Deleting '$strPattern' files created written earlier or on: $strAge"
  
  $strLogFiles = Get-Childitem $strDir -Include $strPattern -Recurse | Where {$_.CreationTime -le $intAge}
 
  foreach ($strLogFile in $strLogFiles) 
  {
    if ($strLogFile -ne $NULL)
    {        
      Write-Log "Deleting $strLogFile"
      Remove-Item $strLogFile.FullName | out-null
      $intFiles++
    }    
  }
  
  Write-Log "$intFiles old log file(s) deleted"  
}