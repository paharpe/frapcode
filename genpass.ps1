#######################################################################################
# Name: genpass.ps1
# Purp: generate a 'random' 8 length password containing Ucase, lCase end N0mb3rs
# Like: 82SkE083
# By  : Found on the internet and slightly changed, PH, 2018-02-16
#######################################################################################

################################################
Function get-pass([int] $intPWlength=8)
################################################
{  
  if ($intPWlength -lt 4)
  {
    return $null
  }

  # Define list of numbers, this will be CharType 1
  $intNumbers=$null
  For ($intIndex=48;$intIndex -le 57;$intIndex++) 
  {
    $intNumbers+=,[char][byte]$intIndex
  }

  # Define list of uppercase letters, this will be CharType 2
  $strUpper=$null
  For ($intIndex=65;$intIndex -le 90;$intIndex++)
  {
    $strUpper+=,[char][byte]$intIndex
  }

  # Define list of lowercase letters, this will be CharType 3
  $strLower=$null
  For ($intIndex=97;$intIndex -le 122;$intIndex++) 
  {
    $strLower+=,[char][byte]$intIndex
  }
 
  # Need to ensure that result contains at least one of each CharType
  # Initialize buffer for each character in the password
  $Buffer = @()
  For ($intIndex=0;$intIndex -le $intPWlength;$intIndex++)
  {
    $Buffer+=0
  }

  # Randomly chose one character to be number
  while ($true)
  {
    $CharNum = (Get-Random -minimum 0 -maximum $intPWlength)
    if ($Buffer[$CharNum] -eq 0) 
    {
      $Buffer[$CharNum] = 1; break
    }
  }

  # Randomly chose one character to be uppercase
  while ($true)
  {
    $CharNum = (Get-Random -minimum 0 -maximum $intPWlength)
    if ($Buffer[$CharNum] -eq 0)
    {
      $Buffer[$CharNum] = 2; break
    }
  }

  # Randomly chose one character to be lowercase
  while ($true)
  {
    $CharNum = (Get-Random -minimum 0 -maximum $intPWlength)
    if ($Buffer[$CharNum] -eq 0)
	{
	  $Buffer[$CharNum] = 3; break
	}
  }

  # Randomly chose one character to be special
  while ($true)
  {
    $CharNum = (Get-Random -minimum 0 -maximum $intPWlength)
    if ($Buffer[$CharNum] -eq 0)
	{
	  $Buffer[$CharNum] = 4; break
	}
  }

  # Cycle through buffer to get a random character from the available types
  # if the buffer already contains the CharType then use that type
  $strPassword = ""
  foreach ($CharType in $Buffer)
  {
    if ($CharType -eq 0)
	{
	  $CharType = ((1,2,3)|Get-Random)
	}
    switch ($CharType) 
    {
       1 {$strPassword+=($intNumbers | GET-RANDOM)}
       2 {$strPassword+=($strUpper   | GET-RANDOM)}
       3 {$strPassword+=($strLower   | GET-RANDOM)}       
    }
  }
  return $strPassword
}