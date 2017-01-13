#!/bin/bash
####################################################################################
# Name: count_obadr.s
#
# Uses: count_obadr.e
#
# Purp: Perform one or more queries todo some counting in (mariadb)amis. tables
#       and write results back to logfile
#
# How :
#    1) The environment file holds an array containing the query/queries
#    2) A loop is initiated in which the mysql command with the appropriate parms
#       is executed for each query from 1)
#
# Date: January 2017 (PH)
#
# Changes:
# -                                                                    (@Who,YYYYMMDD)
#####################################################################################

#set -x
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

#################
function Do_Query {
#################
  QUERY=$1
  echo $(${SQLPATH}/mysql amis -u amis -p${SQLPWD} -se "${QUERY}")
}


#############################################
# INIT
#############################################
TODAY=`date +%Y%m%d`
LOGFILE="${AMIS_COUNT_LOG_PATH}/${AMIS_COUNT_LOG_FNAME}${TODAY}${AMIS_COUNT_LOG_EXT}"

# Write logheader
Write_Head


#############################################
# RUN
#############################################
for SQLQUERY in "${SQLQUERIES[@]}"
do
  SQLRC=`Do_Query "${SQLQUERY}"`
  Write_Log "Result ${SQLQUERY}: ${SQLRC}"
done

# Write logfooter
Write_Tail
