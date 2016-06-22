#!/bin/bash
#################################################################################################
# Name        : addRoute.sh
# Purpose     : add new route(s) using a dynamically determined default gateway
#               The default gateway that belongs to the destination address in var: DESTINATION
#               is programmatically determined and selected
#               New IP addresses should be defined at the Init section in var: DESTINATIONS_NEW
#                                  and the corresponding NetworkMasks  in var: NETMASKS_NEW
# Syntax      : ./addRoute.sh
#
# Parms       : none
# Dependancies: none
# Notes       :
# Author      : PH
# Date        : 2016-06-22
##################################################################################################

##################
function Write-Log {
##################
  LOG_ROW=$1
  echo `date +%H:%M:%S`-${LOG_ROW} >> ${LOG_FILE}
}

###############
function Get-GW {
###############
  IP=$1
  GW=""

  GW=`netstat -nr | grep ^${IP} | xargs | cut -d' ' -f2`
  if [[ ${GW} = "" ]];
  then
    Write-Log "No default gateway could be determined!"
  else
    Write-Log "Default gateway found: ${GW}"
  fi

  echo ${GW}
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

#################################
#LOG
#################################
LOG_PATH="/home/a-pharpe/logs"
LOG_FILENAME="`hostname`_`basename "$0" | cut -d'.' -f1`_`date +%Y-%m-%d`.log"
LOG_FILE=${LOG_PATH}/${LOG_FILENAME}

if [[ ! -d ${LOG_PATH} ]]; then
  echo "Logpath directory ${LOG_PATH} does not exist !"
  exit
fi

##############
# INIT
##############
LOGHEAD="============================================================================="

DESTINATION="145.222.58.0"

DESTINATIONS_NEW="145.222.96.0 145.222.242.0"
NETMASKS_NEW="255.255.252.0 255.255.254.0"

##############
# RUN
##############

Write-Log ${LOGHEAD}
Write-Log "Start run"
Write-Log ${LOGHEAD}

#Get Gateway
GATEWAY=$(Get-GW ${DESTINATION})

if [[ ! ${GATEWAY} = "" ]];
then
  # Create and check IP array
  IFS=' ' read -a DESTINATIONS_NEW_ARRAY <<< "${DESTINATIONS_NEW}"
  A_DEST_NEW_LEN=${#DESTINATIONS_NEW_ARRAY[@]}

  if [[ ${A_DEST_NEW_LEN} -eq 0 ]];
  then
    Write-Log "No new IP-address in inputstring"
    End-of-Job
  fi

  #Create and check Subnet array
  IFS=' ' read -a NETMASKS_NEW_ARRAY <<< "${NETMASKS_NEW}"
  A_MASKS_NEW_LEN=${#NETMASKS_NEW_ARRAY[@]}

  if [[ ${A_MASKS_NEW_LEN} -eq 0 ]];
  then
    Write-Log "No new subnet masks in inputstring"
    End-of-Job
  fi

  #IP and Subnet arrays must be equal in size
  if [[ ${A_DEST_NEW_LEN} -ne ${A_MASKS_NEW_LEN} ]];
  then
    Write-Log "Number of occurrences in the IP table must be equal to those in the Subnet table !"
    End-of-Job
  fi


  # Now, foreach new ip-address in the array, check if the format is OK
  # and do the same for the corresponding subnet mask
  for (( A_DEST_NEW_IND=0; A_DEST_NEW_IND<${A_DEST_NEW_LEN}; A_DEST_NEW_IND++ ));
  do
    IP_NEW=`echo ${DESTINATIONS_NEW_ARRAY[$A_DEST_NEW_IND]} | xargs`
    if [[ $(Is-Good-IP ${IP_NEW}) = true ]];
    then
      MASK_NEW=`echo ${NETMASKS_NEW_ARRAY[$A_DEST_NEW_IND]} | xargs`
      if [[ $(Is-Good-IP ${MASK_NEW}) = true ]];
      then
        # route add ${IP_NEW}<destination IP address> gw <gateway IP address>
        Write-Log "Goede combi: ${IP_NEW} ${MASK_NEW}"
      else
        Write-Log "Subnet ${MASK_NEW} is not a valid mask !"
        End-of-Job
      fi
    else
      Write-Log "IP ${IP_NEW} is not a valid IP address !"
      End-of-Job
    fi
  done
fi

End-of-Job
