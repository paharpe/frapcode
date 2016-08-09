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

################
function Get-eth {
################
  IP=$1
  ETH=""
  ETH=`netstat -nr | grep ^${IP} | xargs | cut -d' ' -f8`
  if [[ ${ETH} = "" ]];
  then
    Write-Log "No ETH route table could be determined!"
  else
    Write-Log "Route table found: ${ETH}"
  fi

  echo ${ETH}

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

#####################
function Is-Good-Mask {
#####################
 IP_NEW=$1
  GOOD=false
  if [[ ${IP_NEW} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
  then
    GOOD=true
  fi
  if [[ ${IP_NEW} =~ ^\/[0-3][0-9]$ ]];
  then
    GOOD=true
  fi
  echo ${GOOD}
}

########################
function Do_route_active {
########################
  IP=$1
  MASK=$2
  bReturn=true

  #When the first position of MASK is a slash(/) then we have to deal with
  #a CIDR notation, and ${MASK}=>/22 or something will be
  #compressed into the IP variabele, so
  #IP  : 144.60.22.1
  #MASK:/22
  #IP <= 144.60.22.1/22
  if [[ ${MASK} =~ ^\/[0-3][0-9]$ ]];
  then
    IP="${IP}${MASK}"
  fi

  ip route add ${IP} via ${GATEWAY}
  if [[ $? -eq 0 ]];
  then
    Write-Log "OK: 'route add' successfully executed"
  else
    Write-Log "ERR: Executing the 'route add' command was unsuccessful !!"
    bReturn=false
  fi
  echo ${bReturn}
}

###########################
function Do_route_passive {
###########################
  IP=$1
  MASK=$2
  bReturn=true

  #When the first position of MASK is a slash(/) then we have to deal with
  #a CIDR notation, and ${MASK}=>/22 or something will be
  #compressed into the IP variabele, so
  #IP  : 144.60.22.1
  #MASK:/22
  #IP <= 144.60.22.1/22
  if [[ ${MASK} =~ ^\/[0-3][0-9]$ ]];
  then
    IP="${IP}${MASK}"
  fi

  IP_EXIST=`grep ${IP_NEW} ${ETH_FILE}`
  if [[ ${IP_EXIST} = "" ]];
  then
    ETH_SAVE="${ETH_FILE}_`date +%Y%m%d_%H%M%N`"
    cp ${ETH_FILE} ${ETH_SAVE}
    if [[ $? -ne 0 ]];
    then
      Write-Log "ERR: Kopie from ${ETH_FILE} to ${ETH_SAVE} was unsuccessful !!!"
      bReturn=false
    else
      Write-Log "OK: Successfully copied ${ETH_FILE} to ${ETH_SAVE}"
      echo "${IP} via ${GATEWAY}" >> ${ETH_FILE}
      if [[ $? -eq 0 ]];
      then
        Write-Log "OK: Successfully appended new route to ${ETH_FILE}"
        bReturn=true
      else
        Write-Log "ERR: Appending new route to ${ETH_FILE} was unsuccesful !!!"
        bReturn=false
      fi
    fi
  else
    Write-Log "ERR: ${IP_NEW} already present in ${ETH_FILE}"
    bReturn=false
  fi
  echo ${bReturn}
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
# LOG_PATH="/home/pharpe/logs"
LOG_PATH="/tmp"
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
# NETMASKS_NEW="255.255.252.0 255.255.254.0"
NETMASKS_NEW="/22 /23"
ROUTE_FILE="/etc/sysconfig/network-scripts/route-"

##############
# RUN
##############

Write-Log ${LOGHEAD}
Write-Log "Start run"
Write-Log ${LOGHEAD}

#Get Gateway
GATEWAY=$(Get-GW ${DESTINATION})

###########################################################
# Vervolgens moet het volgende opgenomen worden in de file
# /etc/sysconfig/network-scripts/route-<mgt_interface>
# waarbij <mgt_interface> de naam van de interface is waar
# het beheer adres van de server op is geconfigureerd.
###########################################################
#Dit wordt uitgezocht via Get-Eth
ETH=$(Get-eth ${DESTINATION})

ETH_FILE="${ROUTE_FILE}${ETH}"
if [[ -f ${ETH_FILE} ]];
then
  NOP=1
else
  Write-Log "${ETH_FILE} does not exist !"
  End-of-Job
fi

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
      if [[ $(Is-Good-Mask ${MASK_NEW}) = true ]];
      then
        # Write-Log "Good combination: ${IP_NEW} ${MASK_NEW}"

        if [[ ${ETH_FILE} = "" ]];
        then
          Write-Log "ERR: EMPTY ${ETH_FILE} variable, should be checked earlier !"
        else
          Write-Log "OK: ${GATEWAY} found in ${ETH_FILE}"
          PASS_OK=$(Do_route_passive  ${IP_NEW} ${MASK_NEW})
          if [[ ${PASS_OK} = true ]];
          then
            ACT_OK=$(Do_route_active ${IP_NEW} ${MASK_NEW})
            if [[ ${ACT_OK} = true ]];
            then
              Write-Log "OK: Active route successfully added"
            else
              Write-Log "ERR: Adding active route was unsuccessful !"
            fi
          else
            Write-Log "ERR: Adding passive route was unsuccessful !"
          fi
        fi

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
