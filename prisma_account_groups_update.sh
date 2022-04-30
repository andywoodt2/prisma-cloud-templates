#!/bin/bash

# This script will upadte an account group.  This process will overwrite the account group contents with the accounts in ./accountids.txt.

# Check if ./accountids.txt exists.  File format must be plaintext, and as written, 1 account per line.
if [ ! -f ./accountids.txt ]; then echo "./accountids.txt file not found.  Exiting...." && exit;
fi

#  Retreive Prisma Cloud write capable API credentials from 1Password 
ONEPWDACCT="[Replace with 1Password name or GUID]"
CREDS=$(op get item $ONEPWDACCT --fields username,credential)
ACCTGRPNAME="[Replace with name of Account Group]"
ACCTGRPID="[Replace with Account Group ID #"
USERNAME=$(awk 'BEGIN{FS="\""}{print$8}' <<< "${CREDS}")
PASSWORD=$(awk 'BEGIN{FS="\""}{print$4}' <<< "${CREDS}")

#Authenticate againt Prisma Cloud.
export PRISMAAPI=$(curl -k -s --request POST --url https://api.prismacloud.io/login --header 'Accept: application/json; charset=UTF-8' --header 'Content-Type: application/json; charset=UTF-8' --data '{"username":'"\"$USERNAME\""',"password":'"\"$PASSWORD\""'}' | awk 'BEGIN { FS="\"" } { print $4 }')

# Formats the input from ./accountids.txt to an array of stings.  This line can be commented out if ./accountids.txt is already in that fornat.
# Array of stirngs format is: "111111111111", "222222222222", "333333333333".  Quote are necessary in this format.
ACCOUNTIDS=$(cat accountids.txt | sed -e 's/^/"/g' -e 's/$/"/g' | sed -z 's/\n/,\ /g' | sed -e 's/..$//')
DESCRIPTION="Maintained by script. Manual updates may be overwritten"


curl -w "%{http_code}\n" -k --request PUT \
  --url https://api.prismacloud.io/cloud/group/$ACCTGRPID \
  --header 'content-type: application/json' \
  --header "x-redlock-auth: $PRISMAAPI" \
  --data '{"accountIds":['"$ACCOUNTIDS"'],"description":'"\"$DESCRIPTION\""',"name":'"\"$ACCTGRPNAME\""'}'
