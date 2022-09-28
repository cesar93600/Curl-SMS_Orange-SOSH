#/bin/bash
log=/dev/null
rm /tmp/Curl-SMS.log 2> $log

# USAGE
usage() {
  echo
  echo " Usage : Curl-SMS.sh  -u <login>  -p <password>  -d <recipient>  -m <message>  [-l] ";
  echo "  -d   recipient phone number, use with country code (+33601020304)";
  echo "  -m   message, special characters must be escaped (\\)";
  echo "  -p   account password";
  echo "  -u   account login (0601020304 or user@mail.com)";
  echo "  -l   (optional) log \"/tmp/Curl-SMS.log\" ";
  echo " Exemples :"
  echo "  Curl-SMS.sh  -u user@mail.com  -p p@ssword  -d +33601020304  -m \"Message...\"";
  echo "  Curl-SMS.sh  -u \"0601020304\"  -p \"p@ss\"  -d \"+33601020304\"  -m \"First line. \nSecond line...\" -l";
  echo
  exit 1;
}

# INIT WITH ARGUMENTS
while getopts "d:m:p:u:l" option; do
  case "${option}" in
    d)
      dest=${OPTARG}
    ;;
    m)
      mess=${OPTARG}
      # REPLACE SPACES BY NBSP (UTF-8)
      mess=$(echo $mess | sed "s/ /\xC2\xA0/g")
    ;;
    l)
      log="/tmp/Curl-SMS.log"
    ;;
    p)
      pass=${OPTARG}
    ;;
    u)
      user=${OPTARG}
    ;;
    *)
      usage
    ;;
  esac
done

# CHECK ARGUMENTS # $#
if [[ $# -lt 8 || -z "$dest" || -z "$mess"  || -z "$pass"  || -z "$user" ]]; then
  usage
fi

# CHECK NETWORK
if ! [[ $(ping 1.1.1.1 -c 1 | grep -i ttl) ]]; then
  echo " Error : Check your internet connection";
  exit 1;
fi

# JSON PARSE
user='{"login":"'$user'","params":{}}'
pass='{"password":"'$pass'","remember":true}'
mess='{"content":"'$mess'","recipients":["'$dest'"],"replyType":"mobile","messageId":"0"}'

# CREATE TMP FILE
touch cookies

# GET SESSION  # SET COOKIES
echo " GET  : SESSION"
curl -Is 'https://login.orange.fr/' -c cookies -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Encoding: gzip, deflate, br' -H 'Connection: keep-alive' > $log

# POST LOGIN  # SET COOKIES
echo " POST : LOGIN"
curl -s 'https://login.orange.fr/api/login' -b cookies -c cookies 'https://login.orange.fr/api/login' -X POST -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' -H 'Accept-Encoding: gzip, deflate, br' -H 'Referer: https://login.orange.fr/' -H 'Content-Type: application/json' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $user >> $log

# POST PASSWORD  # SET COOKIES
echo " POST : SECRET"
curl -s 'https://login.orange.fr/api/password' -b cookies -c cookies -X POST -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' -H 'Accept-Encoding: gzip, deflate, br' -H 'Referer: https://login.orange.fr/' -H 'Content-Type: application/json' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $pass >> $log

# POST TOKEN  # SET COOKIES
echo " GET  : TOKEN"
curl -s 'https://api.webxms.orange.fr/api/v8/token' -b cookies -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: application/json' -H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' -H 'Accept-Encoding: gzip, deflate, br' -H 'x-xms-service-id: OMI' -H 'content-type: application/json' -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://smsmms.orange.fr/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers' > token
token="authorization:  Bearer "$(cat token | cut -f8 -d\")
echo " TRY SEND :" $dest

# POST MESSAGE  # RETURN JSON
result=$(curl -s 'https://api.webxms.orange.fr/api/v8/users/me/messages' -b cookies -X POST -H 'Accept: application/json' -H 'Accept-Encoding: gzip, deflate, br' -H 'x-xms-service-id: OMI' -H 'content-type: application/json' -H "$token" -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'Connection: keep-alive' -H 'Referer: https://smsmms.orange.fr/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers' --data-raw $mess)
echo $result >> $log

# DELETE TEMP FILES
rm cookies

# VERIFY RETURN # JSON
if [[ "$result" == *"\"status\":\"sent\","* ]]; then
  echo " MESSAGE : SENT";
  exit 0;
fi

# RETURN JSON RESULT / IF NOT STATUS SENT
echo " ERROR : MESSAGE NOT SENT"
echo
echo $result;
echo
echo "For more details, you can consult the log file (if -l used)"
exit 1
