#!/bin/bash
####################################################################################################################################################
# Name: check_proxy_status.sh
#
# Purp: Check if all backend services on the HAProxy are running in the requested state
#
#       According to the specifiactions we are only looking 10 minutes back in time, so a 'grep | tail' is performed to limit performance impact
#
#       a  CRITICAL message is returned if non all services are in the required state ( -s <string> state_parm )
#       an OK       message is returned if all services are in the required state     ( -s <string> state_parm )
#
# Deps: ${HTML_INFILE} the hidden file where the wget HTML output is stored. This file is created at the start of this script
#                      and will be read and analysed 
#
# syntax: ./check_proxy_status.sh -s <DOWN|UP>
#
# returns:
# - Unknown message ( rc = 3 )
#   UNKNOWN: inputfile c:\blah\blah\su444v1234.html does not exist !
#   <OR>
# - Critical message( rc = 2 )
#   CRITICAL: not all backends in prd.amsterdam.nl do have required state UP
#   <OR>
# - Ok message ( rc = 0 )
#   OK: all backends in prd.amsterdam.nl have required state UP
#
# (PH), 2018-12-05
#
# Changelog:
################################################################################################################################################

# Get the arguments

while [[ $# > 0 ]]; do
  argument="$1"
  case "$argument" in
     -s|--state)
      state_parm="$2"
      shift
      ;;
    -h|--help)
      helper="help"
      ;;
    -v|--version)
      version="version"
      shift
      ;;
    *)
      ;;
  esac
  shift
done

# Display version and exit when -v|--version is selected
if [[ "$version" == "version" ]]; then
  echo "check_proxy_status v1.0.0"
  echo
  exit 0
fi

# Display help and exit when -h|--help is selected
if [[ "$helper" == "help" ]]; then
  echo
  echo "check_proxy_status help"
  echo
  echo "Usage:"
  echo "  check_proxy_status -s <required_status> "
  echo
  echo "                     -h, --help this help text"
  echo
  exit 0
fi

if [ -z "$state_parm" ]; then
  # Check is variables for the check are all filled in
  echo "No required status specified";
  echo " "
  echo "For more information type: check_proxy_status -h"
  exit 3
fi

###############################################
# MANAGE DESIRED STATE (PARM)
###############################################
STATE_REQUIRED=`echo ${state_parm} | tr a-z A-Z`
# STATE_REQUIRED="DOWN"
if [[ ${STATE_REQUIRED} != "DOWN" && ${STATE_REQUIRED} != "UP" ]];
then
  echo "UNKNOWN: Required status should either be 'UP' or 'DOWN'"
  exit 3
fi 

##############################################
#FUNCTIONS
##############################################
function reset {
  HOST=0
  HOURS=0
  HOST_SAVE=""
  UPDOWN_SAVE=""
}

function process_line {
  if [[ ${HOST_SAVE} != "" && ${UPDOWN_SAVE} != "" ]];
  then
    # fill vars with raw values
    RESPONSE="${HOST_SAVE} is: ${UPDOWN_SAVE}"
    STATE_FOUND=${UPDOWN_SAVE}

    # and remove all unwanted HTML leftovers to get the values cleaned
    for REMOVE in ${REMOVES};
    do
      RESPONSE="${RESPONSE/$REMOVE/}"
      STATE_FOUND="${STATE_FOUND/$REMOVE/}"
    done

    # check if we already got an exception. no further processing in that case
    if [[ ${STATE_FOUND} != ${STATE_REQUIRED} ]];
    then
      echo "CRITICAL: not all backends in ${ENV} have required state '${STATE_REQUIRED}'"
      exit ${CRITICAL}
    fi
    # echo ${RESPONSE}
  fi
} 

##############################################
#INIT
##############################################

# Standard Exit Codes for Nagios
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

REMOVES='name= ></a><a </td><td \" \" :'

HTML_HOST=`hostname`
HTML_PAGE="haproxystats"

# HTML_PATH="/home/a-pharpe"
HTML_PATH="/tmp"
HTML_PAGE="haproxystats"
HTML_FILE="${HTML_PAGE}_${HTML_HOST}.html"
HTML_INFILE="${HTML_PATH}/${HTML_FILE}"
KPN_YAML="/opt/puppetlabs/facter/facts.d/kpn.yaml"

##########################################
#ENVIRONMENT
##########################################
# Check if inputfile exists..
if [[ ! -f ${KPN_YAML} ]]; then
  echo "UNKNOWN: ${KPN_YAML} does not exist !"
  exit ${UNKNOWN}
fi

PUPPET_ENV=`grep customer_environment ${KPN_YAML} | cut -d':' -f2 | tr -d ' '`
# PUPPET_ENV=`facter customer_environment`
case ${PUPPET_ENV} in
   acceptance)
     ENV="acc.amsterdam.nl"
     ;;
   production)
     ENV="prd.amsterdam.nl"
     ;;
   *)
     ENV="tst.amsterdam.nl"
     ;;
esac

SERVS="mijn siam stack1 stack2 citrix pview ami tma"

wget "http://${HTML_HOST}/${HTML_PAGE}" --http-user=admin --http-password=hent! -O ${HTML_INFILE} -o /dev/null

# Check if inputfile exists..
if [[ ! -f ${HTML_INFILE} ]]; then
  echo "UNKNOWN: Inputfile ${HTML_INFILE} does not exist !"
  exit ${UNKNOWN}
fi

#############################################
# Main line
#############################################
for SERV in ${SERVS};
do

  NAME="${ENV}-${SERV}"

  reset

  # Find this type of lines to start with: '<td><input type="checkbox" name="s" value="iamprdsp3.amsterdam.nl"></td'
  LINES=$(grep ${NAME} ${HTML_INFILE} | grep 'type="checkbox" name="s"')
  for LINE in ${LINES};
  do
    # echo ${LINE} >> /home/a-pharpe/scratch.txt
    # and after that search for string: containing: 'name="s"' AND a period(.)
    if [[ "${LINE}" == "name="* && "${LINE}" == *"."* ]];
    then
      # echo "Yes ! found HOST" ${LINE}
      HOST_SAVE=${LINE}
      HOST=1
    else
      # if a host already found, and we meet a string with 'class=ac'
      # we have to setup the next read switch: (HOST=1)
      if [[ ${HOST} -eq 1 && "${LINE}" == "class=ac"* ]];
      then
        # echo "Yes ! found HOURS" ${LINE}
        HOURS=1
      else
        if [[ ${HOST} -eq 1 && ${HOURS} -eq 1 ]];
        then
          UPDOWN_SAVE=${LINE}
          process_line
          reset 
        fi
      fi
    fi
  done
done

process_line

echo "OK: all backends in ${ENV} have required state '${STATE_REQUIRED}'"
rm -f  ${HTML_INFILE}
exit ${OK}
