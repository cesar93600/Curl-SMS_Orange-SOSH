# INIT VARIABLES WITH ARGUMENTS
[CmdletBinding(DefaultParameterSetName="")] Param(
    [Parameter(Mandatory=$false)][AllowEmptyString()] [string[]]$d,
    [Parameter(Mandatory=$false)][AllowEmptyString()] [string[]]$m,
    [Parameter(Mandatory=$false)][AllowEmptyString()] [string[]]$p,
    [Parameter(Mandatory=$false)][AllowEmptyString()] [string[]]$u,
    [switch]$l
);

# INIT
$log = $null;
$tmp = $env:TMP;
$cookies = ($tmp + "\cookies");
$err = 'For more details, you can consult the log file "' + $tmp + '\Curl-SMS.log" (if -l used)';

# REMOVE PREVIOUS FILES
Remove-Item ($tmp + "\Curl-SMS.log") 2>&1 > $log;
Remove-Item $cookies 2>&1 > $log;

# INIT LOG
if($l){
    $log = ($tmp + "\Curl-SMS.log");
};

# USAGE
Function usage {
    Write-Host @"

 Usage : Curl-SMS -u <login> -p <password> -d <recipient> -m <message>  [-l]
  -d   recipient phone number, use with country code (+33601020304)
  -m   message, special characters must be escaped (\)
  -p   account password
  -u   account login (0601020304 or user@mail.com)
  -l   (optional) log "%temp%\Curl-SMS.log"

 Exemples :
  Curl-SMS -u user@mail.com -p p@ssword -d +33601020304 -m "Message..."
  Curl-SMS -u "0601020304" -p "p@ss" -d "+33601020304" -m "First line. \nSecond line..." -l
"@;
exit 1;
};

# NO ARGUMENT
if ($PSCmdlet.ParameterSetName -eq ""){
    usage;
    exit 1;
}

# CHECK ARGUMENTS
if(!$d -or !$m -or !$p -or !$u){
    usage;
    exit 1;
}

# CHECK NETWORK
if((ping 1.1.1.1 -n 1 | findstr /I "TTL").Length -eq 0 ){
    echo " Error : Check your internet connection";
    exhit 1;
}

# JSON PARSE
$u=('{\"login\":\"' + $u + '\",\"params\":{}}');
$p=('{\"password\":\"' + $p + '\",\"remember\":false}');
$m=('{\"content\":\"' + ($m.Replace(" ","\u00A0")) + '\",\"recipients\":[\"' + $d + '\"],\"replyType\":\"mobile\",\"messageId\":\"0\"}'); # REPLACE SPACES BY NBSP (UTF-8)

# PARAMETERS
$UserA = 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0';
$Accept = 'Accept: application/json, text/plain';
$AcceptL = 'Accept-Language: en-US,en;q=0.5';
$AcceptE = 'Accept-Encoding: gzip, deflate, br';
$Conn = 'Connection: keep-alive';
$ContT = 'content-type: application/json';

# GET SESSION  # SET COOKIES
Write-Host " GET  : SESSION";
curl.exe -Is 'https://login.orange.fr' -c $cookies -H $Accept -H $AcceptE -H $Conn > $log;

# POST LOGIN  # SET COOKIES
Write-Host " POST : LOGIN";
curl.exe -s 'https://login.orange.fr/api/login' -X POST -c $cookies -b $cookies -H $ContT -H $Accept -H $AcceptL -H $AcceptE -H $UserA  -H $Conn -H 'Referer: https://login.orange.fr/' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $u >> $log

# POST PASSWORD  # SET COOKIES
Write-Host " POST : SECRET";
curl.exe -s 'https://login.orange.fr/api/password' -X POST -c $cookies -b $cookies -H $ContT -H $Accept -H $AcceptL -H $AcceptE -H $UserA -H $Conn  -H 'Referer: https://login.orange.fr/' -H 'Origin: https://login.orange.fr' -H 'DNT: 1' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-raw $p >> $log

# GET TOKEN
Write-Host " GET  : TOKEN";
$token = curl.exe -s 'https://api.webxms.orange.fr/api/v8/token' -b $cookies -H $ContT -H $Accept -H $AcceptL -H $AcceptE -H $UserA  -H $Conn -H 'x-xms-service-id: OMI' -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'DNT: 1' -H 'Referer: https://smsmms.orange.fr/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers'

try {
  $token = ('authorization: Bearer ' + $token.Substring($token.IndexOf("token") + 8, + $token.IndexOf("expires") - $token.IndexOf("token") - 11));
}
catch {
  "
 ERROR : TOKKEN
 MESSAGE : NOT SENT
  
 " + $err;
  Remove-Item $tmp\cookies 2>&1 > $null;
  exit 1;
};

# POST MESSAGE  # RETURN JSON
Write-Host " TRY SEND : " + $d;
$result = curl.exe -s 'https://api.webxms.orange.fr/api/v8/users/me/messages' -X POST -b $cookies -H $token -H $ContT -H $Accept -H $AcceptL -H $AcceptE -H $UserA -H $Conn -H 'x-xms-service-id: OMI' -H 'cache-control: no-cache' -H 'Pragma: no-cache' -H 'if-none-match: 0' -H 'Origin: https://smsmms.orange.fr' -H 'DNT: 1' -H 'Referer: https://smsmms.orange.fr/'  -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'TE: trailers' --data-raw $m

# DELETE TMP FILES
Remove-Item $tmp\cookies 2>&1 > $null;

# VERIFY RETURN # JSON
if( $result.Contains('"status":"sent"') ) {
  Write-Host " MESSAGE : SENT";
  echo $result > $log;
  exit 0;
}

# RETURN JSON RESULT / IF STATUS NOT SENT
Write-Host " ERROR : MESSAGE NOT SENT

 " + $result + "

 " + $err;
exit 1;
