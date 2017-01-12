#!/bin/bash
####################################################################################
# Name: xml_import.s
#
# Uses: xml_import.e
#
# Purp: Refresh AMIS data 
#
# How : 
#   1) Check for (new) XML-file and /Images directory in FTP dir. Third party
#      should deliver a whole new set or additions to /Images every night.
#   2) Move the XML-file and /Images directory to the location the php scripts
#      are expecting their stuff..
#   3) Issue a wget command to trigger the data import
#
# Date: October 2016 (PH)
#
# Changes:
# - Instead of moving the XML file and the \Images directory they are 
#   copied now leaving the contents of the FTP directory in place.      (PH,20161027)
# - Inserted code to cleanup my own logfiles older than <@env> days     (PH,20161031)
# - Added code to maintain only 1 version of file 'import.php?auto=true'(PH,20161109)
# - Count contents of ../Images dir now using `ls` instead of `ls -l`   (PH,20161118)
# - Added --timeout=0 option to 'wget' commandstring			(PH,20161123)	
# - Removed --timeout=0 option to 'wget' commandstring                  (PH,20170112)
#####################################################################################
# set -x
SCRIPT=`basename $0`
SCRIPTNAME=`echo ${SCRIPT} | cut -d'.' -f1`

v_dir=$(dirname $0)/.
if [[ -f ${v_dir}/${SCRIPTNAME}.e ]];
then
  . ${v_dir}/${SCRIPTNAME}.e
else
  #************************
  # NO environmentfile !!!
  #************************
  echo "${SCRIPT}: environmentfile is missing !"
  exit
fi

##############################################
# root ??
##############################################
if [[ `whoami` != "root" ]];
then
   echo "${SCRIPT}: should be ran by user root"
   exit
fi


##############################################
# Check paths
##############################################
if [[ ! -d ${AMIS_IMPORT_LOG_PATH} ]];
then
  #************************
  #Not existing logdir !!
  #************************
  echo "${SCRIPT}: logdirectory ${AMIS_IMPORT_LOG_PATH} does not exist !"
  exit
fi

 
if [[ ! -d ${AMIS_FTP_PATH} ]];
then
  #********************************
  #Not existing AMIS ftp dir!!
  #Thats where the external party 
  # people are putting their stuff...
  #********************************
  echo "${SCRIPT}: FTP import directory ${AMIS_FTP_PATH} does not exist !"
  exit
fi


if [[ ! -d ${AMIS_IMPORT_PATH} ]];
then
  #********************************
  #Not existing AMIS import path !!
  #Thats where the php scripts are
  #expecting their input to be
  #********************************
  echo "${SCRIPT}: php import directory ${AMIS_IMPORT_PATH} does not exist !"
  exit
fi


##############################################
# Functions
##############################################

###################
function Write_Log {
###################
  LOG_ROW=$1
  if [[ ${LOG_ROW} == "<SPACE>" ]];
  then
    echo " " >> ${LOGFILE}
  else
    echo `date +%H:%M:%S`-${LOG_ROW} >> ${LOGFILE}
  fi
}


####################
function Check_Input {
####################
  FILE=$1
  RC=-1
  if [[ -f ${FILE} ]];
  then
    RC=0
  fi
  echo ${RC}
}


##################
function Load_Data {
##################
  # Wget may return one of several error codes if it encounters problems. 
  # - 0 No problems occurred. 
  # - 1 Generic error code. 
  # - 2 Parse error—for instance, when parsing command-line options, the ‘.wgetrc’ or ‘.netrc’... 
  # - 3 File I/O error. 
  # - 4 Network failure. 
  # - 5 SSL verification failure. 
  # - 6 Username/password authentication failure. 
  # - 7 Protocol errors. 
  # - 8 Server issued an error response

  wget --no-check-certificate ${AMIS_IMPORT_URL} 
  RC=$?
  echo ${RC}
}


###################
function Write_Head {
###################
  Write_Log "**********************************************"
  Write_Log "Start ${SCRIPT}"
  Write_Log "**********************************************"
}


###################
function Write_Tail {
###################
  Write_Log "**********************************************"
  Write_Log "End ${SCRIPT}"
  Write_Log "**********************************************"
  Write_Log "<SPACE>"
} 


############################
function Delete_Old_Run_Logs {
############################
  OLDLOGS_TOT=`find ${AMIS_IMPORT_LOG_PATH} -mtime +${AMIS_IMPORT_LOG_MAX_AGE} | wc -l`
  OLDLOGS=`find ${AMIS_IMPORT_LOG_PATH} -mtime +${AMIS_IMPORT_LOG_MAX_AGE}`
  Write_Log "Cleaning up logfiles.."
  if [[ ${OLDLOGS_TOT} -lt 1 ]];
  then
    Write_Log "No logfile(s) older than ${AMIS_IMPORT_LOG_MAX_AGE} day(s)"
  else
    Write_Log "Deleting ${OLDLOGS_TOT} logfile(s) older than ${AMIS_IMPORT_LOG_MAX_AGE} day(s)"
    for OLDLOG in ${OLDLOGS};
    do
      Write_Log "Deleting: "${OLDLOG}
      rm -f ${OLDLOG}
      RC=$?
      if [[ ! ${RC} -eq 0 ]];
      then
        Write_Log "Warning: ${RC} occurred while removing ${OLDLOG} !"
      fi
    done
  fi
  Write_Log "<SPACE>"
}


###############################
function Move_Previous_HTML_Log {
###############################
# Every run causes a 'import.php?auto=true' file to be created in directory '/boot'
# That's why a series of 'import.php?auto=true.0', 'import.php?auto=true.1' .. 'import.php?auto=true.n'
# was developing over a couple of rundays
# Underneath code moves and overwrites 'import.php?auto=true' from '/boot' to '/var/log/amis'   
# This is how we maintain only 2 versions:
# - Yesterdays HTML log in /var/log amis AND
# - The current (last) in /root
  find ${AMIS_IMPORT_HTML_LOG_PATH} -name ${AMIS_IMPORT_HTML_FILE} -exec mv -t ${AMIS_IMPORT_LOG_PATH}/ {} \+
}


##########
# Init
##########
TODAY=`date +%Y%m%d`
LOGFILE="${AMIS_IMPORT_LOG_PATH}/${AMIS_IMPORT_LOG_FNAME}${TODAY}${AMIS_IMPORT_LOG_EXT}"

# Write logheader
Write_Head

# Take care of old logfile(s)
Delete_Old_Run_Logs
Move_Previous_HTML_Log
 

###############################################################
# Mainline
###############################################################
# The full XML name location
AMIS_IMPORT_XML=${AMIS_FTP_PATH}/${AMIS_IMPORT_XML_FILE}

# The full /Imagages name and location
AMIS_IMPORT_IMAGES=${AMIS_FTP_PATH}/${AMIS_IMPORT_IMAGES_DIR}

# Do we have the required input objects ?
if [[ $(Check_Input "${AMIS_IMPORT_XML}") -ne 0 ]];
then
  Write_Log "Error: XML inputfile (${AMIS_IMPORT_XML}) not delivered by third party so it does not exist !"
  Write_Tail
  exit
else
  if [[ ! -d ${AMIS_IMPORT_IMAGES} ]];
  then
    Write_Log "Error: /Images directory ${AMIS_IMPORT_IMAGES} not delivered by third party so it does not exist !"
    Write_Tail
    exit
  fi
fi


# ****************************************************************
# OK, XML file and /Images directory are present, lets continue...
# ****************************************************************
# Count XML lines and Images
LINES=`cat ${AMIS_IMPORT_XML} | wc -l`
IMAGES=`ls ${AMIS_IMPORT_IMAGES} | wc -l`

Write_Log "OK: both XML file and /Images directory are present containing ${LINES} XML-lines and ${IMAGES} images"

# Now copy the input from the FTP location to the location php expects it..
cp -p -f ${AMIS_IMPORT_XML} ${AMIS_IMPORT_PATH}
RC=$?
if [[ ! ${RC} -eq 0 ]];
then
  Write_Log "Error: ${RC} occurred while moving the XML file from FTP to PHP location !"
  Write_Tail
  exit
fi

# Now we have todo some extra stuff to move the Images directory and
# its contents to to PHP location:
# 1: Does the "/Images" subdir exist ?
#      NO: Create it
#      YES: Does it contain any files ?
#        NO: OK: move can be done without further issues
#        YES: Delete all files in "/Images" prior to move from FTP to PHP
AMIS_IMPORT_PHP_IMAGES_DIR=${AMIS_IMPORT_PATH}/${AMIS_IMPORT_IMAGES_DIR}
if [[ ! -d ${AMIS_IMPORT_PHP_IMAGES_DIR} ]];
then
  # PHP Images directory does not exist ! Create it
  mkdir ${AMIS_IMPORT_PHP_IMAGES_DIR}
  RC=$?
  if [[ ${RC} -eq 0 ]];
  then
    Write_Log "OK: Directory ${AMIS_IMPORT_PHP_IMAGES_DIR} succesfully created !"
  else 
    Write_Log "Error: ${RC} occurred while trying to create ${AMIS_IMPORT_PHP_IMAGES_DIR}"
    Write_Tail
    exit
  fi
else
  # PHP Images directory did already exist ! remove (yesterdays) jpg's
  IMAGES=`ls ${AMIS_IMPORT_PHP_IMAGES_DIR} | wc -l`
  rm -f ${AMIS_IMPORT_PHP_IMAGES_DIR}/*
  RC=$?
  if [[ ${RC} -eq 0 ]];
  then
    Write_Log "OK: Directory ${AMIS_IMPORT_PHP_IMAGES_DIR} succesfully cleared, ${IMAGES} existing images removed"
  else
    Write_Log "Error: Directory ${AMIS_IMPORT_PHP_IMAGES_DIR} not cleared, ${IMAGES} existing images remain"
    Write_Tail
    exit
  fi
fi
# Copy the JPG's; 
cp -p -f ${AMIS_IMPORT_IMAGES}/* ${AMIS_IMPORT_PHP_IMAGES_DIR} 
RC=$?
if [[  ${RC} -eq 0 ]];
then
  Write_Log "OK: Images succesfully copied from ${AMIS_IMPORT_IMAGES} to ${AMIS_IMPORT_PHP_IMAGES_DIR}"
else
  Write_Log "Error: ${RC} occurred while copy'ing the /Images directory from FTP to PHP location !"
  Write_Tail
  exit
fi

Write_Log "OK: both XML file and the /Images directory are copied from FTP to PHP location"

# ****************
# Start the IMPORT
# ****************
RC=$(Load_Data "${XML_URL}")
if [[ ${RC} -eq 0 ]];
then
  Write_Log "OK: Import succesfull"
else
  Write_Log "Error: Import failed, RC=${RC} !"
fi

Write_Tail
