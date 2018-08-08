##############################################################
# Code to be included, should be used to cleanup old logfiles
# Parms: 1 logdirectory   z.b.: C:\management\logs
#        2 pattern        z.b.: Restart_log*.log
#        3 number of days z.b.: 31
#
# PH, 2017-10-05
# Changed: $strPattern needed wildcard *, without this no
#          logfile cleaning was done ( PH, 2017-12-22 )
# Changed: Varnames $strLogFile and $strLogFiles changed to
#                   $strCleanLog    $strCleanLogs 
##############################################################
function Cleanup-Log($strDir, $strPattern, $intDays)
{
  # Check if logdirectory exists
  if ( Test-Path $strDir ) 
  {
    $strDir = $strDir
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
  else
  # Add wildcard char
  {
    $strPattern = $strPattern + "*.log"
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
  $strAge     = $intAge.ToString("yyyy-MM-dd")

  Write-Log "Deleting '$strPattern' files created written earlier or on: $strAge"

  $strCleanLogs = Get-Childitem $strDir -Filter $strPattern | Where {$_.Extension -eq ".log" -and $_.CreationTime -le $intAge}
 
  foreach ($strCleanLog in $strCleanLogs) 
  {
    if ($strCleanLog -ne $NULL)
    {        
      Write-Log "Deleting $strCleanLog"
      # Remove-Item $strCleanLog.FullName | out-null
      $intFiles++
    }    
  }
  
  Write-Log "$intFiles old log file(s) deleted"  
}