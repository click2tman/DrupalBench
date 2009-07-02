#!/bin/bash
read -p "Drupal Login: " DUSER;
stty -echo 
read -p "Password: " DPASS;
stty echo
#DUSER=''
#DPASS=''
DPASS=$(echo -n "${DPASS}" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')

tempsub=`basename $0`
COOKIEFILE=`mktemp /tmp/${tempsub}.XXXXXX` || exit 1
SITE="${!#}"

# figure out the base site URL to contruct the URL for the login page
## remove trailing slash
BASESITE=$(echo ${SITE%/})
while true
do
  SUB=$(echo ${BASESITE##*/})
  HTTPCODE=$(curl -s --output /dev/null -w "%{http_code}\n" ${BASESITE}/update.php)
  if [[ "${HTTPCODE}" != 403 && "${HTTPCODE}" != 404 ]]
  then
    break
  fi
  BASESITE=$(echo ${BASESITE} | sed "s/\/${SUB}//")
done

LOGINURL="${BASESITE}/user"
POSTVARS="name=${DUSER}&pass=${DPASS}&form_id=user_login&op=Log+in"
RESPONSE=$(curl -s -k -d "${POSTVARS}" -c ${COOKIEFILE} ${LOGINURL})

if [[ -z "${RESPONSE}" ]]
then
  ABCOOKIE=$(grep "SESS" ${COOKIEFILE} | awk '{print $6"="$7}')
  # run ab with cookie info and any arguments passed to this script
  ## uncomment if you want to see the ab command that's run..
  #echo "ab -C ${ABCOOKIE} $@" 1>&2
  ab -C ${ABCOOKIE} $@
else
  echo "Login failed!" 1>&2
fi

rm ${COOKIEFILE}
