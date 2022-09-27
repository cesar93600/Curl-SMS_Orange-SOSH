#/bin/bash

# CHECK ARGUMENTS
if  [[ -z $1 || -z $2 || -z $3 || -z $4 || $# != 4 ]]; then
  echo " Argument error";
  echo " Usage : Curl-SMS.sh  <login>  <password>  <recipient>  <message>";
  echo " Exemple : Curl-SMS.sh  user@mail.com p@ssword +33601020304 'Votre message...' ";
  echo " Exemple : Curl-SMS.sh  0601020304 p@ss +33601020304 'Première ligne. \n deuxième ligne...' ";
  exit 1;
fi

# INIT
user=$1, pass=$2, dest=$3, mess=$(echo $4 | sed "s/ / /g")

# JSON PARSE
user='{"login":"'$user'","params":{}}'
pass='{"password":"'$pass'","remember":true}'
mess='{"content":"'$mess'","recipients":["'$dest'"],"replyType":"mobile","messageId":"0"}'

# GET SESSION  # SET COOKIES
echo "Session"
curl -Is 'https://login.orange.fr/' -c cookies -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept>
# POST LOGIN  # SET COOKIES
echo "Identifiant"
curl -s 'https://login.orange.fr/api/login' -b cookies -c cookies 'https://login.orange.fr/api/login' -X POST -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; >
# POST PASSWORD  # SET COOKIES
echo "Mot de passe"
curl -s 'https://login.orange.fr/api/password' -b cookies -c cookies -X POST -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100>
# POST TOKEN  # SET COOKIES
echo "Token"
curl -s 'https://api.webxms.orange.fr/api/v8/token' -b cookies -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/10>token="authorization:  Bearer "$(cat token | cut -f8 -d\")
echo "Envoi SMS :" $dest

# POST MESSAGE  # RETURN JSON
result=$(curl -s 'https://api.webxms.orange.fr/api/v8/users/me/messages' -X POST -H 'Accept: application/json' -H 'Accept-Encoding: gzip, deflate, br' -H 'x>
# VERIFY RETURN JSON
if [[ "$result" == *"\"status\":\"sent\","* ]]; then
  echo "Message envoyé...";
  exit 0;
fi

# RETURN JSON RESULT / IF NOT STATUS SENT
echo $result;
exit 1
