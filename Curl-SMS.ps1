# INIT
$user="0601020304"
$pass="p@ss"
$dest="+33601020304"
$mess="Votre message"

# JSON PARSE
$user=('{\"login\":\"'+$user+'\",\"params\":{}}')
$pass=('{\"password\":\"'+$pass+'\",\"remember\":false}')
$mess=('{\"content\":\"'+($mess.Replace(" "," "))+'\",\"recipients\":[\"'+$dest+'"],\"replyType\":\"mobile\",\"messageId\":\"0\"}')

# GET SESSION  # SET COOKIES
echo "Session"
curl.exe -Is 'https://login.orange.fr/' -c .\.Cookies -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: none' -H 'Sec-Fetch-User: ?1' | Out-Null

# POST LOGIN  # SET COOKIES
echo "Identifiant"
curl.exe -s 'https://login.orange.fr/api/login' -X POST -c .\.Cookies -b .\.Cookies -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Referer: https://login.orange.fr/' -H 'Content-Type: application/json' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $user | Out-Null

# POST PASSWORD  # SET COOKIES
echo "Mot de passe"
curl.exe -s 'https://login.orange.fr/api/password' -X POST -c .\.Cookies -b .\.Cookies -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Referer: https://login.orange.fr/' -H 'Content-Type: application/json' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $pass | Out-Null

# POST TOKEN  # SET COOKIES
echo "Token"
$token = curl.exe -s 'https://api.webxms.orange.fr/api/v8/token' -b .\.Cookies -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: application/json' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'x-xms-service-id: OMI' -H 'content-type: application/json' -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://smsmms.orange.fr/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers'
try {
  $token = ('authorization: Bearer ' + $token.Substring($token.IndexOf("token") + 8, + $token.IndexOf("expires") - $token.IndexOf("token") - 11))
}
catch {
  ""
  "TOKEN ERROR !"
  exit 1
}

# POST MESSAGE  # RETURN JSON
echo ("Envoi SMS : " + $dest)
$result = curl.exe -s 'https://api.webxms.orange.fr/api/v8/users/me/messages' -X POST -b .\.Cookies -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0' -H 'Accept: application/json' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'x-xms-service-id: OMI' -H 'content-type: application/json' -H $token -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://smsmms.orange.fr/'  -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers' --data-raw $mess

# POST MESSAGE  # RETURN JSON
if( $result.Contains('"status":"sent"') ) {
  echo "Message envoyé."
  exit 0
}

echo $result
exit 1
