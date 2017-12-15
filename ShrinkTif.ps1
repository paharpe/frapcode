############################################################################################################################
# Code to be included, should be used to shrink TIF files from
# regual Tif to Tif_lzw format, which causes the tif file
# to be reduced in filesize dramatically. This comes in handy
# when e-mailing this failed TIF's 
#
# Parms: 1 Tif file ( including full path )
# Bijv : E:\Decos\DATA\scansource\BARCODE\failed\389378a21v2813fv.tif
#
# Que? : 1) INFILE : E:\Decos\DATA\scansource\BARCODE\failed\389378a21v2813fv.tif              (MEGA)
#
#        2) PROCES : IrfanView convert INFILE to E:\Decos\DATA\scansource\BARCODE\failed\LZW_389378a21v2813fv.tif
#
#        3) DELETE : E:\Decos\DATA\scansource\BARCODE\failed\389378a21v2813fv.tif
#
#        4) RENAME : E:\Decos\DATA\scansource\BARCODE\failed\LZW_389378a21v2813fv.tif 
#                 => E:\Decos\DATA\scansource\BARCODE\failed\389378a21v2813fv.tif
#
#        5) OUTFILE: E:\Decos\DATA\scansource\BARCODE\failed\389378a21v2813fv.tif              (MICRO)
#
# PH, 2017-12-15
###########################################################################################################################
function ShrinkTif($strTifFile)
{

  ###################################################
  # INIT
  ###################################################
  $strIrfan="c:\Program Files\IrfanView\i_view64.exe"
  
  ###################################################
  # Prechecks
  ###################################################
  if ( $strTifFile -eq "" -or $strTifFile -eq $null)
  {
    Write-Log "Missing Tif file: should be passed as parm (1)"
    Exit
  }

  if ( -Not ( Test-Path $strTifFile ))
  {
    Write-Log "File ($strTifFile) does not exist !"
    exit
  }
  
  if ( -Not ( Test-Path $strIrfan ))
  {
    Write-Log "IrFanView does not exist in $strIrfan"
    exit
  } 
 
  #################################################
  # Main line
  #################################################
  # Write-Log "File $strTifFile found, start processing..."

  $strTifPath = Split-Path $strTifFile
  $strLZWName = Split-Path $strTifFile -Leaf
  $strLZWName = $strTifPath + "\LZW_" + $strLZWName

  $intB4Size= [math]::Round(((Get-Item "$strTifFile").length/1MB),2)

  ##############################
  # COMPOSE cmd
  ##############################
  #/tifc compressions: 0 = None, 1 = LZW, 2 = Packbits, 3 = Fax3, 4 = Fax4, 5 = Huffman, 6 = JPG, 7 = ZIP
  $strFromTif2LZW = "$strTifFile /tifc=1 /convert=$strLZWName"

  ##############################
  # RUN cmd
  ##############################
  & $strIrfan $strFromTif2LZW
  $bRC=$?

  # Wait for Irfanview to finish, otherwise the new written outputfile does not exist yet!
  ##############################
  # WAIT for cmd
  ##############################
  while ($true)  
  {
    Start-Sleep -Seconds 1
    if (-not (Get-Process -Name i-view64 -ErrorAction SilentlyContinue))
    {
      break
    }
  }

  ##############################
  # CHECK outputfile
  ##############################
  if ( -not ( Test-Path $strLZWName )) 
  {
    Write-Log "Outputfile $strLZWName does not exist! "
    exit
  }

  ##############################
  # CHECK returncode cmd
  ##############################
  if ( -not ($bRC -eq $true ))
  { 
    Write-Log "Returncode from Irfanview was False!"
    exit
  } 
  else
  {  
    $intAfterSize= [math]::Round(((Get-Item "$strLZWName").length/1MB),2)
    Write-Log "Size b4: $intB4Size after: $intAfterSize" 
   
    Remove-Item $strTifFile
    $bRC=$?
    if (-not ( $bRC -eq $true ))
    {
      Write-Log "Something went wrong during delete of $strTifFile "
      exit
    }
    else
    {
      $strLZWName | Rename-Item -NewName $strTifFile
      $bRc=$?
      if ( -not ( $bRC -eq $true ))
      {
        Write-Log "Something went wrong during renaming from $strLZWName to $strTifFile"
        exit
      }
    }
  }
}