#!/bin/bash
###########################################################################
# Name: logclear.sh
#
# Purp: Zip old (log)files having a certain age ( var: $COMPRESSIFOLDERTHAN )
# Uses: logclear.env
# Log : logclear.log ( either in @scriptpath or in /var/log )
#
# Miscelaneous:
# - Filenames to be compressed MUST contain a date in YYYY-MM-DD format
#
# Date: August 2016 (PH)
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
  exit
fi

if [[ -d ${LOGPATH} ]];
then
  LOGFILE="${LOGPATH}/${SCRIPTNAME}.log"
else
  LOGFILE="${v_dir}/${SCRIPTNAME}.log"
fi

##################
function Write-Log {
##################
LOG_ROW=$1
  echo `date +%H:%M:%S`-${LOG_ROW} >> ${LOGFILE}
}

####################
function Write-Debug {
####################
  if [[ ${DEBUG} = 1 ]];
  then
    LOG_ROW=$1
    echo `date +%H:%M:%S`-${LOG_ROW} >> ${LOGFILE}
  fi
}

# Return # days since FILE was CHANGED
##############
function AGE() {
##############
   local FILENAME=$1
   local CHANGED=`stat -c %Y "$FILENAME"`
   local NOW=`date +%s`
   local AGE

   let AGE=$(((NOW-CHANGED)/60/60/24))
   echo ${AGE}
}

#################
function ISOPEN() {
#################
# Check if file is open ( cmd "lsof" is not installed on all servers )
  local FILENAME=$1
  local BOPEN=0
  local OPENID=`for p in [0-9]*; do ls -l /proc/$p/fd | grep ${FILENAME} ;done`
  if [[ ${OPENID} != "" ]];
  then
    BOPEN=1
  fi
  echo ${BOPEN}
}

##############
function zip() {
##############
  local FILENAME=$1

  #Initial: Assume file does not exist or does not have a YYYY-MM-DD pattern in its name
  local AGE=-1

  # ONLY if a FILENAME contains YYYY-MM-DD !!!
  case ${FILENAME} in *2[0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]* )
    if [[ -f ${FILENAME} ]]; then
      AGE=$(AGE "${FILENAME}")
      ISCOMPRESSED=`file ${FILENAME} | cut -d':' -f2 | xargs | cut -d' ' -f2`
      #Already zipped ?
      if [[ ${ISCOMPRESSED} != "compressed" ]];
      then
        if [[ $(ISOPEN "${FILENAME}") -eq 0 ]];
        then
          AGE=$(AGE "${FILENAME}")
        else
          #File is OPEN
          AGE="-3"
        fi
      else
        #File already COMPRESSED
        AGE="-2"
      fi
    fi

    if [[ ${AGE} -gt ${COMPRESSIFOLDERTHAN} ]];
    then
      Write-Debug "gzip ${FILENAME}"
      # gzip ${FILENAME}
    fi

    ;;
  esac

  echo ${AGE}
}

Write-Log "*********************************************************************************"
Write-Log "LogClean start"

########################
# Check number of parms
########################
if [[ $# -gt 1 ]];
then
  Write-Log "Too many parms !"
  exit
fi

#############
# TELLERS
#############
FILESREAD=0
COMPRESSED=0
ALREADY=0
IGNORED=0
OPEN=0
TOORECENT=0

for CLEAN in ${CLEANUP};
do
  FILESREAD=$((FILESREAD + 1))

  if [[ ${CLEAN} = "" ]];
  then
    ####################
    # Nothing          #
    ####################
    Write-Log "ERR: No input"
    exit
  elif [[ -f ${CLEAN} ]];
  then
    ###################
    # Single FILE     #
    ###################
    RC=$(zip "${CLEAN}")
    Write-Debug "OK: Processing single file: ${CLEAN} RC=${RC}"
    if [[ ${RC} -gt ${COMPRESSIFOLDERTHAN} ]];
    then
      COMPRESSED=$((COMPRESSED + 1))
    elif [[ ${RC} -eq -1 ]]
    then
      IGNORED=$((IGNORED + 1))
    elif [[ ${RC} -eq -2 ]]
    then
      ALREADY=$((ALREADY + 1))
    elif [[ ${RC} -eq -3 ]]
    then
      OPEN=$((OPEN + 1))
    else
      TOORECENT=$((TOORECENT + 1))
    fi
  else
    ###################
    # UnkNOWn         #
    ###################
    Write-Log "ERR: Unknown objecttype"
   # exit
  fi

done
Write-Log "LogClean finished, counters:"
Write-Log "---------------------------------------------------------------------"
Write-Log "Files read.....................: ${FILESREAD}"
Write-Log " "
Write-Log "Files too recent to compress...: ${TOORECENT}"
Write-Log "Files compressed by this run...: ${COMPRESSED}"
Write-Log "Files already compressed.......: ${ALREADY}"
Write-Log "Filenames without date pattern.: ${IGNORED}"
Write-Log "Files having status 'open'.....: ${OPEN}"
Write-Log "*********************************************************************************"
Write-Log " "
