##############################################################
# PH, 2017-10-05
# Code to be included, should be used to cleanup old logfiles
##############################################################
function Cleanup-Log($strDir, $strPattern, $intDays)
{
  if ( Test-Path $strDir ) 
  {
    # Nop
  }
  else
  {
    echo "Parm path $strDir doest not exist !"
    exit
  }

  if ( $strPattern -eq "" )
  {
    echo "File pattern is empty !"
    exit
  }

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
  $strPattern = "$strMyName*.log"
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
  return $intFiles
}