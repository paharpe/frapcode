################################################################################################
# Naam      : QPatch.ps1
#
# Doel      : Uitlezen zipfile en uitzoeken welke ".config" files hierin zitten.
#             vervolgens zoeken in de D:\Decos* directory structuur waar
#
# Aanleiding: Decos levert regelmatig Hotfixes uit zonder dat wordt gemeld op welke directory
#             deze van toepassing zijn.
#             Met behulp van dit script worden de .config files die zich in de zip file bevinden
#             geidentificeerd, en vervolgens wordt naar overeenkomstige files gezocht binnen
#             de Decos installatie directories. Op deze manier wordt een beeld gekregen waarin
#             de HotFix geinstalleerd moet worden.
#
# Flow      : 1) Kies een zip file m.b.v. een Fileopen dialog
#             2) Decos install directory (zie: $strDecosInstallPath) wordt doorzocht op 
#                aanwezigheid van bepaalde bestanden/stypen (zoals aangegeven in $strConfigFile).
#                Het resultaat wordt weggeschreven in een rapportfiletje (zie: $strPatchReport)
#             3) Tot slot wordt gevraagd of het rapportfiletje moet worden getoond in Notepad
#
#
# Restrictie: Script kan alleen worden uitgevoerd als minimaal .Net Framwork 4.5 aanwezig is
#
# Door      : PH, 2018-02-13
################################################################################################


################################################################################################
# Check
################################################################################################
$dotnetversion = [Environment]::Version            
if (!($dotnetversion.Major -ge 4 -and $dotnetversion.Build -ge 30319)) 
{            
  write-error "You are not having Microsoft DotNet Framework 4.5 installed. Script exiting"            
  exit(1)            
}        


################################################################################################
# Functions
################################################################################################
Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "ZIP (*.zip)| *.zip"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename    
}

Function Write-Report([string] $strRecord)
{
  if ( $strRecord.ToUpper() -eq "INIT".ToUpper() )
  {
    echo " " > $strPatchReport;
  } 
  else
  {
    $strDate=(Get-Date).ToString("yyyyMMdd")  
    $strTime=(Get-Date).ToString("HHmmss") 
    echo "$strHsName-$strDate-$strTime : $strRecord" >> $strPatchReport 
    
  }
}

Function Read-Zipfile($strZipFile, $strConfig)
{
  [string] $strPatchReport = "$strDecosTemp\"+ ($strZipFile | Split-Path -Leaf ).replace($strExt,".log");
  
  Write-Report "INIT";
  
  [Void][Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')            

  if (Test-Path $strZipFile)
  {    
    Write-Report "-----------------------------------------------------------------------------------------------------------";
    Write-Report "Analyzing $strZipFile"
    Write-Report "-----------------------------------------------------------------------------------------------------------";
       
    Write-Report " ";
    Write-Report "|                   Config in zipfile                |                   Found in Decos dir               |"
    Write-Report "+----------------------------------------------------+----------------------------------------------------+" 
    
     
    $arPackedFiles = [IO.Compression.ZipFile]::OpenRead($strZipFile).Entries  
    [string] $strPackedFile          
    foreach($strPackedFile in $arPackedFiles)
    {   
      if ( $strPackedFile.FullName.Contains($strConfigFile) )
      {
        # write-host "$strPackedFile";
        $strDecosDirs=( Get-ChildItem -Path $strDecosInstallPath -Recurse "$strPackedFile" | Split-Path | Convert-Path );
       
       
        foreach ($strDecosDir in $strDecosDirs) 
        {
          $strConfigFile_fmt=$strPackedFile.ToString().PadRight(50);
          $strDecosDir_fmt=$strDecosDir.PadRight(50);

          Write-Report "| $strConfigFile_fmt | $strDecosDir_fmt |";
          Write-Report "+----------------------------------------------------+----------------------------------------------------+" 
        }
      }         
    }
    
    # Notepad installed ? Then ask
    if ( Test-Path $strNotePad )
    { 
      clOpenReport $strPatchReport
    }             
  } 
  else
  {            
    Write-Warning "$strPatchFile File path not found"              
  }  
}

Function clOpenReport([string] $strPatchReport)
{
  Add-Type -AssemblyName PresentationCore,PresentationFramework
  $ButtonType = [System.Windows.MessageBoxButton]::YesNo
  $MessageIcon = [System.Windows.MessageBoxImage]::Question
  $MessageBody = "Open logfile $strPatchReport ?"
  $MessageTitle = "Just asking..."
 
  $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
 
  if ( $Result.ToString().ToUpper() -Eq "yEs".ToUpper() ) 
  {    
    Start-Process $strNotePad "$strPatchReport"
  }  
}

Function clCheckPath([string] $strCheckPath)
{
  if ( ! ( Test-Path $strCheckPath ) )
  {
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    $MessageBody = "$strCheckPath does not exist !"
    $MessageTitle = "Error"
 
    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon) 
    
    exit -1 
  }
}
  
#################################################################################################
# Init
#################################################################################################
[string] $strPatchPath        = "D:\_install\Patches\"
[string] $strConfigFile       = ".config"
[string] $strDecosInstallPath = "D:\Decos"
[string] $strExt              = ".zip"
[string] $strDecosTemp        = $strDecosInstallPath+"\DATA\temp"
[string] $strNotePad          = "C:\windows\system32\notepad.exe"
[string] $strHsName           = hostname 


#################################################################################################
# Checks
#################################################################################################
clCheckPath $strPatchPath
clCheckPath $strDecosInstallPath
 
#################################################################################################
# Mainline
#################################################################################################

# Which hotfix zipper ??
[string] $strPatchFile = Get-FileName $strPatchPath
if ( $strPatchFile -eq $null -or $strPatchFile -eq "" )
{
  write-host "Geen file gekozen"
  exit
}
else
{   
   Read-Zipfile $strPatchFile $strConfigFile
}             