#!/bin/bash
###########################################################################
# Name: xml_import.sh
#
# Uses: xml_import.env
#
# Purp: Refresh AMIS data
#
# How :
#   1) Check for (new) zipfile
#   2) Extract data from zipfile:
#      a) XML data
#      b) jpg images
#   3) Issue a wget command to trigger the data import
#
# Date: October 2016 (PH)
############################################################################
# set -x
SCRIPT=`basename $0`
SCRIPTNAME=`echo ${SCRIPT} | cut -d'.' -f1`

v_dir=$(dirname $0)/.
if [[ -f ${v_dir}/${SCRIPTNAME}.env ]];
then
  . ${v_dir}/${SCRIPTNAME}.env
else
  #************************
  # NO environmentfile !!!
  #************************
  echo "${SCRIPT}: environmentfile is missing !"
  exit
fi

##############################################
# Check paths
##############################################
if [[ ! -d ${XML_IMPORT_LOG_PATH} ]];
then
  #************************
  #Not existing logdir !!
  #************************
  echo "${SCRIPT}: logdirectory  ${XML_IMPORT_LOG_PATH} does not exist !"
  exit
fi

if [[ ! -d ${XML_IMPORT_ZIPIN_PATH} ]];
then
  #*********************************
  #Not existing inputdir Zipfile !!
  #*********************************
  echo "${SCRIPT}: Zipfile inputdirectory  ${XML_IMPORT_ZIPIN_PATH} does not exist !"
  exit
fi

if [[ ! -d ${XML_IMPORT_ZIPOUT_PATH} ]];
then
  #*********************************
  #Not existing outputdir Zipfile !!
  #*********************************
  echo "${SCRIPT}: Zipfile outputdirectory  ${XML_IMPORT_ZIPOUT_PATH} does not exist !"
  exit
fi


##############################################
# Functions
##############################################

###################
function Write_Log {
###################
  LOG_ROW=$1
  echo `date +%H:%M:%S`-${LOG_ROW} >> ${LOGFILE}
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

##############
function Unzip {
##############
  ZIPIN=$1
  ZIPOUT_PATH=$2
  unzip -o -q ${ZIPIN} -d ${ZIPOUT_PATH}
  RC=$?
  # 10 = foute dir na -d
  echo ${RC}
}

##################
function Load_Data {
##################
  # The 'real' wget still has to be coded here.
  # At this moment it
 # allowed
  Write_Log "wget ${XML_URL}"
  #RC=$?
  RC=999
  echo ${RC}
}


##########
# Init
##########
TODAY=`date +%Y%m%d`
LOGFILE="${XML_IMPORT_LOG_PATH}/${XML_IMPORT_LOG_FNAME}${TODAY}${XML_IMPORT_LOG_EXT}"
ZIPIN="${XML_IMPORT_ZIPIN_PATH}/${XML_IMPORT_ZIPIN_FNAME}"

Write_Log "**********************************************"
Write_Log "Start ${SCRIPT}"
Write_Log "**********************************************"

###############################################################
# Mainline
###############################################################
if [[ $(Check_Input "${ZIPIN}") -eq 0 ]];
then
  # ZIPIN_STAMP=`ls -la ${ZIPIN}`
  Write_Log "Inputfile found: `ls -la ${ZIPIN}`"}
  if [[ $(Unzip "${ZIPIN}" "${XML_IMPORT_ZIPOUT_PATH}") -eq 0 ]];
  then
    # Count XML lines and Images
    LINES=`cat ${XML_IMPORT_ZIPOUT_PATH}/${XML_IMPORT_ZIPOUT_FNAME} | wc -l`
    IMAGES=`ls -l ${XML_IMPORT_ZIPOUT_PATH}/${XML_IMPORT_ZIPOUT_IMAGES} | wc -l`

    Write_Log "Extract succeeded, (${LINES} XML-lines and ${IMAGES} images)"
    if [[ $(Load_Data "${XML_URL}" ) -eq 0 ]];
    then
      Write_Log "Import succeeded"
    else
      Write_Log "Import failed"
    fi
  else
    Write_Log "Extract failed"
  fi
else
  Write_Log "Inputfile ${ZIPIN} does not exist !"
fi

Write_Log "**********************************************"
Write_Log "End ${SCRIPT}"
Write_Log "**********************************************"
Write_Log " "
