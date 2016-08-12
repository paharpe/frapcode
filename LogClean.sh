#!/bin/bash
function age() {
   local filename=$1
   local changed=`stat -c %Y "$filename"`
   local now=`date +%s`
   local age

   let age=$(((now-changed)/60/60/24))
   echo ${age}
}

function zip() {
  local filename=$1
  local age=-1
  if [[ -f ${filename} ]]; then
    age=$(age "${filename}")
# file dpd-DWIT-ms2.log.2016-08-01.1.gz  | cut -d':' -f2 | xargs | cut -d' ' -f2 geeft: "compressed"
  fi
  echo ${age}
}

function dodir() {
  local  files=`ls ${1}`
  for file in ${files};
  do
    echo $(zip "$1/$file")
  done
}

if [[ ${1} = "" ]];
then
  ####################
  # Nothing          #
  ####################
  echo "No input"
  exit
elif [[ -d ${1} ]];
then
  ####################
  # Whole DIRECTORY  #
  ####################
  dodir ${1}
elif [[ -f ${1} ]];
then
  ###################
  # Single FILE     #
  ###################
  echo $(zip "${1}")
else
  ###################
  # Unknown         #
  ###################
  echo "None of the above"
  exit
fi
