###############################
# Functions
###############################
function Write-Log([string]$strLogData)  
{  
  $strDate=(Get-Date).ToString("yyyyMMdd")   
  $strTime=(Get-Date).ToString("HHmmss")  
  # "$strHostName-$strDate-$strTime : $strLogData" >> $strLogFile  
  Write-Host "$strHostName-$strDate-$strTime : $strLogData"
  }  



###############################
# Initialisatie
###############################
[string] $strBasePath="D:\_install\patches\hotfixes\6.25_TEST"
[string] $strHostName= hostname
[string] $strFile="blah"
[int] $intLentgh=0
[int]$intStart=0;
[int]$intEnd=0;
[string]$strPossibleDate
[DateTime]$dtDateTime
[Boolean]$bDateOK=$False
    
###############################
# Check
###############################
if ( -not ( Test-Path $strBasePath ))  
{ 
  Write-Log "Patchdirectory '$strBasePath' does not exist " 
  exit 
}  
else
{
  Write-Log "Start processing"
  Write-Log "Checking files...."

  $arFiles= Get-ChildItem -Path "D:\_install\Patches\Hotfixes\6.25_TEST" -Name

  ForEach ( $strFile in $arFiles )
  {
   #  Write-Host $strFile
    $strFileTab=$strFile -split '\.'
    if ( $strFileTab[-1+$strFileTab.Length].ToUpper() -eq "zip".ToUpper() )
    {
      #-Log "File "+$strFile+ " has the good extension"      
    }
    else
    {
      Write-Log "File $strFile has the wrong extension"
    }

    # Here we are going to split the file var repeatedly in portions of 8 chars
    $intLength=$strFile.Length-1;
    $intStart=0;
    $intEnd=8;
    $bDateOK=$False    
    While ( $intStart+6 -lt $intLength)
    {
      $strPossibleDate=$strFile.Substring($intStart, $intEnd);
      $dtDateTime=try{ [datetime]::parseexact($strPossibleDate, 'yyyymmdd', $null) } catch{}
      if ( $dtDateTime )
      {
        $bDateOk=$true
        # Write-Host "OK  $strPossibleDate"
      }
      $intStart++;
    }
    if ( -not $bDateOK )
    {
      Write-Log "File $strFile does not contain a valid date "
    }       
  }
} 