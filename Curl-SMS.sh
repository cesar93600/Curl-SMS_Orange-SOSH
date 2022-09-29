#/bin/bash

# INIT
log=/dev/null;
tmp=/tmp/;
cookies="$tmp""cookies";
err="For more details, you can consult the log file \"""$tmp""Curl-SMS.log\" (if -l used)";

# REMOVE PREVIOUS FILES
rm "$tmp""Curl-SMS.log" 2> $log;
rm "$cookies" 2> $log;

# USAGE
usage() {
  echo "
 Usage : Curl-SMS -u <login> -p <password> -d <recipient> -m <message>  [-l]
  -d   recipient phone number, use with country code (+33601020304)
  -m   message, special characters must be escaped (\\)
  -p   account password
  -u   account login (0601020304 or user@mail.com)
  -l   (optional) log \""$tmp"Curl-SMS.log\"

 Exemples :
  Curl-SMS -u user@mail.com -p p@ssword -d +33601020304 -m \"Message...\"
  Curl-SMS -u \"0601020304\" -p \"p@ss\" -d \"+33601020304\" -m \"First line. \nSecond line...\" -l
  ";
  exit 1;
};

# INIT WITH ARGUMENTS
while getopts "d:m:p:u:l" option; do
  case "${option}" in
    d)
      dest=${OPTARG};
    ;;
    m)
      mess=${OPTARG};
      # REPLACE SPACES BY NBSP (UTF-8)
      mess=$(echo $mess | sed "s/ /\xC2\xA0/g");
    ;;
    l)
      log="/tmp/Curl-SMS.log";
    ;;
    p)
      pass=${OPTARG};
    ;;
    u)
      user=${OPTARG};
    ;;
    *)
      usage;
    ;;
  esac
done;

# CHECK ARGUMENTS # $#
if [[ $# -lt 8 || -z "$dest" || -z "$mess"  || -z "$pass"  || -z "$user" ]]; then
  usage;
fi;

# CHECK NETWORK
if ! [[ $(ping 1.1.1.1 -c 1 | grep -i ttl) ]]; then
  echo " Error : Check your internet connection";
  exit 1;
fi;

# JSON PARSE
user='{"login":"'$user'","params":{}}';
pass='{"password":"'$pass'","remember":false}';
mess='{"content":"'$mess'","recipients":["'$dest'"],"replyType":"mobile","messageId":"0"}';

# PARAMETERS
UserA="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0";
Accept="Accept: application/json, text/plain";
AcceptL="Accept-Language: en-US,en;q=0.5";
AcceptE="Accept-Encoding: gzip, deflate, br";
Conn="Connection: keep-alive";
ContT="content-type: application/json";

# GET SESSION  # SET COOKIES
echo " GET  : SESSION";
curl -Is 'https://login.orange.fr' -c $cookies -H "$Accept" -H "$AcceptE" -H "$Conn" > $log;

# POST LOGIN  # SET COOKIES
echo " POST : LOGIN";
curl -s 'https://login.orange.fr/api/login' -X POST -c $cookies  -b $cookies -H "$ContT" -H "$Accept" -H "$AcceptL" -H "$AcceptE" -H "$UserA" -H "$Conn" -H 'Referer: https://login.orange.fr/' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $user >> $log;

# POST PASSWORD  # SET COOKIES
echo " POST : SECRET";
curl -s 'https://login.orange.fr/api/password' -X POST -c $cookies -b $cookies -H "$ContT" -H "$UserA" -H "$Accept" -H "$AcceptL" -H "$AcceptE" -H "$Conn" -H 'Referer: https://login.orange.fr/' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $pass >> $log;

# GET TOKEN
echo " GET  : TOKEN";
token=$(curl -s 'https://api.webxms.orange.fr/api/v8/token' -b $cookies -H "$ContT" -H "$UserA" -H "$Accept" -H "$AcceptL" -H "$AcceptE" -H "$Conn" -H 'x-xms-service-id: OMI' -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'DNT: 1' -H 'Referer: https://smsmms.orange.fr/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers');

if [[ "$token" == *"\"token\":"* ]]; then
  token="authorization:  Bearer "$(echo $token | cut -f8 -d\");
else
  echo "
 ERROR : TOKKEN
 MESSAGE : NOT SENT
  
 ""$err";
  rm $cookies;
  exit 1;
fi;

# POST MESSAGE  # RETURN JSON
echo " TRY SEND :" $dest;
result=$(curl -s 'https://api.webxms.orange.fr/api/v8/users/me/messages' -X POST -b $cookies -H "$token" -H "$ContT" -H "$Accept" -H "$AcceptL" -H "$AcceptE" -H "$Conn" -H 'x-xms-service-id: OMI' -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'Referer: https://smsmms.orange.fr/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers' --data-raw $mess);

# DELETE TMP FILES
rm $cookies;

# VERIFY RETURN # JSON
if [[ "$result" == *"\"status\":\"sent\","* ]]; then
  echo " MESSAGE : SENT";
  echo $result > $log;
  exit 0;
fi;

# RETURN JSON RESULT / IF STATUS NOT SENT
echo "
 ERROR : MESSAGE NOT SENT

 ""$result""

 ""$err""
";
exit 1;
