# Curl-SMS (Orange/SOSH) - Script Windows/Linux
Envoi de SMS (Orange/SOSH) via l'outil Curl.

### Nécessite :
- Curl, Wget
- Forfait Orange/SOSH (NVMO Orange à vérifier)
- Accéder une première fois à l'espace abonné depuis un navigateur pour activer le service [SMSMMS Orange](https://smsmms.orange.fr).
- Ne pas activer l'authentification à 2 facteurs.

## Utilisation script Curl-SMS.sh (Linux)
```
wget https://raw.githubusercontent.com/cesar93600/Curl-SMS_Orange-SOSH/main/Curl-SMS.sh
chmod +x ./Curl-SMS.sh
./Curl-SMS.sh
```

### Persister Curl-SMS (Linux)
```
wget https://raw.githubusercontent.com/cesar93600/Curl-SMS_Orange-SOSH/main/Curl-SMS.sh
sudo chmod +x ./Curl-SMS.sh
sudo mv ./Curl-SMS.sh /usr/local/bin/Curl-SMS
Curl-SMS
```


## Utilisation script Curl-SMS.ps1 (Windows)
```
wget "https://raw.githubusercontent.com/cesar93600/Curl-SMS_Orange-SOSH/main/Curl-SMS.ps1" -OutFile ".\Curl-SMS.ps1"
.\Curl-SMS.ps1
```

### Gestion de la stratégie d’exécution avec PowerShell [Source Microsoft](https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.2)
```
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
