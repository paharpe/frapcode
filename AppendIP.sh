#!/bin/bash

###############################################################################################
# Name        : AppendIP.sh
# Purpose     : Concatenate an additional string containing IP-addresses to an existing string
#               in $FLATIN_FILE
# Syntax      : ./AppendIP.sh
# Parms       : none
# Dependancies: none
# Files       : Inputfile is read and wil be renamed to save version: inputfile_yyyymmdd_hhmmss
#             : Outputfile containing the change is first named inputfilename_TMP
#             : After successful operations the Outputfile is renamed back to Inputfile
#             : Logfile is named something like @Serverid_AppendIP_yyyy-mm-dd.log
# Notes       : All settings should be made in the Init (1) section
# Author      : PH
# Date        : 2016-06-22
###############################################################################################

##################
function Write-Log {
##################
  LOG_ROW=$1
  echo `date +%H:%M:%S`-${LOG_ROW} >> ${LOG_FILE}
}

#################
function Exist-IP {
#################
  EXIST=false
  for (( A_NOW_IND=0; A_NOW_IND<${A_NOW_LEN}; A_NOW_IND++ ));
  do
    IP_NOW=`echo ${IPS_NOW_ARRAY[$A_NOW_IND]} | xargs`
    if [[ ${IP_NEW} = ${IP_NOW} ]];
    then
      EXIST=true
      break
    fi
  done
  # echo "en exist isw ${EXIST}"
  echo ${EXIST}
}

###################
function Is-Good-IP {
###################
  IP_NEW=$1
  GOOD=false
  if [[  ${IP_NEW} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
  then
    GOOD=true
  fi
  echo ${GOOD}
}

###################
function End-of-Job {
###################
  Write-Log ${LOGHEAD}
  Write-Log "End run"
  Write-Log ${LOGHEAD}

  exit
}

###############################################
# INIT
###############################################

################################
#LOG
#################################
LOG_PATH="/home/a-pharpe/logs"
LOG_FILENAME="`hostname`_`basename "$0" | cut -d'.' -f1`_`date +%Y-%m-%d`.log"
LOG_FILE=${LOG_PATH}/${LOG_FILENAME}

if [[ ! -d ${LOG_PATH} ]]; then
  echo "Logpath directory ${LOG_PATH} does not exist !"
  exit
fi


################################
#Input
################################
NOW_FULL=`date +%Y-%m-%d' '%H:%M:%S`

#PROD
#FLATIN_PATH="/usr/local/nagios/etc"
#TEST
FLATIN_PATH="/home/a-pharpe/data"

FLATIN_FILENAME="nrpe.cfg"
FLATIN_FILE=${FLATIN_PATH}/${FLATIN_FILENAME}
FLATIN_FILE_TEMP="${FLATIN_FILE}_TMP"
FLATIN_FILE_SAVE="${FLATIN_FILE}_`date +%Y%m%d_%H%M%S`"

###############################
#Other
###############################
LOGHEAD="========================================================================"

TARGET="allowed_hosts"
APPEND="145.222.242.160,145.222.242.161,145.222.242.162,145.222.242.163,145.222.242.164,145.222.242.165,145.222.242.166,145.222.242.167,145.222.242.168,145.222.242.169,145.222.242.170,145.222.242.171,145.222.242.172,145.222.242.173,145.222.242.174,145.222.242.175,145.222.242.176,145.222.242.177,145.222.242.178,145.222.242.179,145.222.242.180,145.222.242.181,145.222.242.182,145.222.242.183,145.222.242.184,145.222.242.185,145.222.242.186,145.222.242.187,145.222.242.188,145.222.242.189,145.222.242.190,145.222.242.191,145.222.99.64,145.222.99.65,145.222.99.66,145.222.99.67,145.222.99.68,145.222.99.69,145.222.99.70,145.222.99.71,145.222.99.72,145.222.99.73,145.222.99.74,145.222.99.75,145.222.99.76,145.222.99.77,145.222.99.78,145.222.99.79,145.222.99.80,145.222.99.81,145.222.99.82,145.222.99.83,145.222.99.84,145.222.99.85,145.222.99.86,145.222.99.87,145.222.99.88,145.222.99.89,145.222.99.90,145.222.99.91,145.222.99.92,145.222.99.93,145.222.99.94,145.222.99.95,145.222.99.96,145.222.99.97,145.222.99.98,145.222.99.99,145.222.99.100,145.222.99.101,145.222.99.102,145.222.99.103,145.222.99.104,145.222.99.105,145.222.99.106,145.222.99.107,145.222.99.108,145.222.99.109,145.222.99.110,145.222.99.111,145.222.99.112,145.222.99.113,145.222.99.114,145.222.99.115,145.222.99.116,145.222.99.117,145.222.99.118,145.222.99.119,145.222.99.120,145.222.99.121,145.222.99.122,145.222.99.123,145.222.99.124,145.222.99.125,145.222.99.126,145.222.99.127,145.222.99.160,145.222.99.161,145.222.99.162,145.222.99.163,145.222.99.164,145.222.99.165,145.222.99.166,145.222.99.167,145.222.99.168,145.222.99.169,145.222.99.170,145.222.99.171,145.222.99.172,145.222.99.173,145.222.99.174,145.222.99.175,145.222.99.176,145.222.99.177,145.222.99.178,145.222.99.179,145.222.99.180,145.222.99.181,145.222.99.182,145.222.99.183,145.222.99.184,145.222.99.185,145.222.99.186,145.222.99.187,145.222.99.188,145.222.99.189,145.222.99.190,145.222.99.191"
"

#############################################
# START
#############################################
Write-Log ${LOGHEAD}
Write-Log "Start run"
Write-Log ${LOGHEAD}

##############################################
# CHECK
##############################################
if [[ ! -f ${FLATIN_FILE} ]]; then
  Write-Log "Inputfile does not exist"
  End-of-Job
fi

###############################
# PUT existing IP's in an array
###############################
IPS_NOW_FULL=`grep ^${TARGET} ${FLATIN_FILE}`

IPS_NOW=`grep ^${TARGET} ${FLATIN_FILE} | cut -d'=' -f2`
IFS=',' read -a IPS_NOW_ARRAY <<< "${IPS_NOW}"

A_NOW_LEN=${#IPS_NOW_ARRAY[@]}

if [[ ${A_NOW_LEN} -eq 0 ]];
then
  Write-Log "Target ${TARGET} not found !"
  End-of-Job
fi


##########################
# PUT new IP's in an array
##########################
IPS_NEW=${APPEND}

IFS=',' read -a IPS_NEW_ARRAY <<< "${IPS_NEW}"
A_NEW_LEN=${#IPS_NEW_ARRAY[@]}

if [[ ${A_NEW_LEN} -eq 0 ]];
then
  Write-Log "No new IP-address in inputstring"
  End-of-Job
else
  # Now, foreach new ip-address in the array, find out if this address
  # already exists and build a new string ( APPEND_NEW ) with addresses
 # to be added later on
  APPEND_NEW=""
  for (( A_NEW_IND=0; A_NEW_IND<${A_NEW_LEN}; A_NEW_IND++ ));
  do
    IP_NEW=`echo ${IPS_NEW_ARRAY[$A_NEW_IND]} | xargs`
    if [[ $(Is-Good-IP ${IP_NEW}) = true ]];
    then
      # echo "${A_NEW_IND}  ${IP_NEW}"
      if [[ $(Exist-IP ${IP_NEW}) = true ]];
      then
        :
        # echo "${IP_NEW}  already exists !"
      else
        # echo  "${IP_NEW} does not exist (yet)"
        APPEND_NEW="${APPEND_NEW},${IP_NEW}"
      fi
    else
      Write-Log "${IP_NEW} is not a correct IP-address !"
      End-of-Job
    fi
  done

  if [[ "${APPEND_NEW}" = "" ]];
  then
    # Nothing new !
    Write-Log "All new IP addresses already exist !"
  else
    # echo "The new to append string is:  ${APPEND_NEW}"
    IPS_NEW_FULL="${IPS_NOW_FULL}${APPEND_NEW}"
    # echo ${IPS_NEW_FULL}

    # Insert the changed string into the new ( temporary ) file
    sed "s/${IPS_NOW_FULL}/${IPS_NEW_FULL}/g" "${FLATIN_FILE}" > ${FLATIN_FILE_TEMP}
    if [[ -s ${FLATIN_FILE_TEMP} ]];
    then
      Write-Log "Succesfully created ${FLATIN_FILE_TEMP}"
      # Rename the original working version file to Save file version
      mv ${FLATIN_FILE} ${FLATIN_FILE_SAVE}
      if [[ $? -eq 0 ]];
      then
        Write-Log "Succesfully renamed ${FLATIN_FILE} to ${FLATIN_FILE_SAVE}"
        # Rename the changed file to the new working verion
        mv ${FLATIN_FILE_TEMP} ${FLATIN_FILE}
        if [[ $? -eq 0 ]];
        then
          Write-Log "Succesfully renamed ${FLATIN_FILE_TEMP} to ${FLATIN_FILE}"
        else
          Write-Log "Rename changed file to working version NOT successful !"
        fi
      else
        Write-Log "Rename working version to SAVE file NOT successful !"
      fi
 else
      Write-Log "Temporary file ${FLATIN_FILE_TEMP} contains no data !"
    fi
  fi
fi

End-of-Job
