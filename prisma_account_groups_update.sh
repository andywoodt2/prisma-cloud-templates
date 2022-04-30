#!/bin/bash

#  This script will upadte an account group.  This process will overwrite the account group contents with the accounts in ./accountids.txt.
#  I'm not a fan of using "-k" in the cURL commands, but hey, it's cURL, the certs are EC, and cURL reports that the key is too small.  Well DUH! 521 bits does *SEEM* small, but isn't.

#  Check if ./accountids.txt exists.  File format must be plaintext, and contain 1 12-character account nunber per line.
if [ ! -f ./accountids.txt ]; then echo "./accountids.txt file not found.  Exiting...." && exit;
fi

#  Retreive Prisma Cloud write capable API credentials from 1Password 
ONEPWDACCT="[Replace with 1Password API credential name or GUID]"
#  To note: While requesting the fields "username,credential", the order retreived will be "credential,username".
CREDS=$(op get item $ONEPWDACCT --fields username,credential)
ACCTGRPNAME="[Replace with name of the Account Group]"
ACCTGRPID="[Replace with ID # of the Account Group]"
USERNAME=$(awk 'BEGIN{FS="\""}{print$8}' <<< "${CREDS}")
PASSWORD=$(awk 'BEGIN{FS="\""}{print$4}' <<< "${CREDS}")

#  Authenticate againt Prisma Cloud.
export PRISMAAPI=$(curl -k -s --request POST --url https://api.prismacloud.io/login --header 'Accept: application/json; charset=UTF-8' --header 'Content-Type: application/json; charset=UTF-8' --data '{"username":'"\"$USERNAME\""',"password":'"\"$PASSWORD\""'}' | awk 'BEGIN { FS="\"" } { print $4 }')

#  Formats the input from ./accountids.txt to an array of stings.  This line can be commented out if ./accountids.txt is already in that fornat.
#  Array of stirngs format is: "111111111111", "222222222222", "333333333333".  Quote are necessary in this format.
ACCOUNTIDS=$(cat accountids.txt | sed -e 's/^/"/g' -e 's/$/"/g' | sed -z 's/\n/,\ /g' | sed -e 's/..$//')
DESCRIPTION="Maintained by script. Manual updates may be overwritten"

#  The "description" and "name" require adding literal quotation marks surrounding the expanded variables". The other single and double quote syntax, when using variables is very cURL specific.
#  Command should output a "200" status, else something went wrong.
curl -w "%{http_code}\n" -k --request PUT \
  --url https://api.prismacloud.io/cloud/group/$ACCTGRPID \
  --header 'content-type: application/json' \
  --header "x-redlock-auth: $PRISMAAPI" \
  --data '{"accountIds":['"$ACCOUNTIDS"'],"description":'"\"$DESCRIPTION\""',"name":'"\"$ACCTGRPNAME\""'}'
