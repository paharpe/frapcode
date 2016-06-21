#!/bin/bash

##################
function Write-Log {
##################
  LOG_ROW=$1
  echo `date +%k:%M:%S`-${LOG_ROW} >> ${LOG_FILE}
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
NOW_FULL=`date +%Y-%m-%d' '%k:%M:%S`
FLATIN_PATH="/usr/local/nagios/etc"
FLATIN_FILENAME="nrpe.cfg"
FLATIN_FILE=${FLATIN_PATH}/${FLATIN_FILENAME}

###############################
#Other
###############################
TARGET="allowed_hosts"
APPEND="143.60.88.13, 145.222.98.143 , 10.0.0.1"

##############################################
# CHECK
##############################################
if [[ ! -f ${FLATIN_FILE} ]]; then
  Write-Log "Inputfile does not exist"
  exit
fi

#############################################
# START
#############################################

###############################
# PUT existing IP's in an array
###############################
IPS_NOW=`grep ^${TARGET} ${FLATIN_FILE} | cut -d'=' -f2`
IFS=',' read -a IPS_NOW_ARRAY <<< "${IPS_NOW}"

A_NOW_LEN=${#IPS_NOW_ARRAY[@]}

if [[ ${A_NOW_LEN} -eq 0 ]];
then
  Write-Log "Target ${TARGET} not found !"
  exit
fi


##########################
# PUT new IP's in an array
##########################
IPS_NEW=${APPEND}
IFS=',' read -a IPS_NEW_ARRAY <<< "${IPS_NEW}"

A_NEW_LEN=${#IPS_NEW_ARRAY[@]}

if [[ ${A_NEW_LEN} -eq 0 ]];
then
  Write-Log "No new IP-address in string"
  exit
else
  for (( A_NEW_IND=0; A_NEW_IND<${A_NEW_LEN}; A_NEW_IND++ ));
  do
    IP_NEW=`echo ${IPS_NEW_ARRAY[$A_NEW_IND]} | xargs`
    if [[  ${IP_NEW} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      echo "${A_NEW_IND}  ${IP_NEW}"
      RC=Exist-IP ${IP_NEW}
echo ${RC}
      if [[ ${RC} = true ]];
      then
        echo "${IP_NEW}  bestaat al !"
      else
        echo  "${IP_NEW}  bestaat niet !"
      fi
    else
      Write-Log "${IP_NEW} is not a correct IP-address !"
      exit
    fi
  done
fi
