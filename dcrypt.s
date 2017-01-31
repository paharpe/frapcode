#!/bin/bash
# set -x
#INIT
PW="PoaSeisheiwi9eiz"
CK="@"

echo "Input PW: ${PW}"

#CRYPT
PWS=`echo ${PW} | openssl enc -aes-128-cbc -a -salt -pass pass:${CK}`
echo "Crypted PW: ${PWS}"

#DECRYPT
echo "Decrypted again"
echo ${PWS} | openssl enc -aes-128-cbc -a -d -salt -pass pass:${CK}
