# Installer certbot
Ajouter à `/etc/apt/sources.list`:
```
deb http://ftp.debian.org/debian jessie-backports main
```
Mettre à jour puis installer certbot
```
sudo apt update
sudo apt install -t jessie-backports  certbot
```

# Préparer la réception du challenge
## Fichier d'inclusion pour le challenge letsencrypt

Créer le fichier `/etc/nginx/includes/letsencrypt.conf`
```
location ^~ /.well-known/acme-challenge {
    alias /var/lib/letsencrypt/.well-known/acme-challenge;
    default_type "text/plain";
    try_files $uri =404;
}
```
## Editer le fichier de virtualhost

Éditer `/etc/nginx/sites-available/monsite.conf` 
```
server {
    listen 80;
    server_name monsite.mondomain.tutu;
    include includes/letsencrypt.conf;
    root /srv/http/monsite;
    location / {
       index  index.html index.htm index.php;
   }
   include includes/php.conf;
   error_page   500 502 503 504  /50x.html;
   location = /50x.html {
       root   /usr/share/nginx/html;
   }
}
```
Penser à activer le site

```
sudo ln -s /etc/nginx/{sites-available/monsite.conf,sites-enabled}
```

Puis à recharger nginx

```
sudo systemctl reload nginx
```
# Générer le certificat

Lancer la génération du certificat
```
sudo certbot certonly --webroot --webroot-path /var/lib/letsencrypt
```
La seule chose que va demander le script dans ces conditions est le nom de domaine à certifier (ici monsite.mondomain.tutu)

Si le message suivant apparaît, c'est réussi :
```
IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at
   /etc/letsencrypt/live/monsite.mondomain.tutu/fullchain.pem. Your cert will
   expire on 2017-09-10. To obtain a new or tweaked version of this
   certificate in the future, simply run certbot again. To
   non-interactively renew *all* of your certificates, run "certbot
   renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```
# Inclure le certificat
## Créer l'include adapté

Créer le fichier  `/etc/nginx/includes/certificate_monsite_mondomain.conf`
```
listen       443 ssl;
ssl_certificate /etc/letsencrypt/live/monsite.mondomain.tutu/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/monsite.mondomain.tutu/privkey.pem;
```

## Ajouter la ligne adaptée dans le virtualhost

Sous la ligne
```
    include includes/letsencrypt.conf
```
Ajouter
```
    include includes/certificate_monsite_mondomain.conf;
```

Bien laisser la ligne d'include pour le challenge, on ne sait jamais !

Et penser à recharger nginx :
```
sudo systemctl reload nginx
```

# Programmer le renouvellement automatique des certificats
## Fichier timer

Créer le fichier `/etc/systemd/system/certbot.timer`
```
[Unit]
Description=Daily renewal of Let's Encrypt's certificates

[Timer]
OnCalendar=daily
RandomizedDelaySec=1day
Persistent=true

[Install]
WantedBy=timers.target%
```
## Fichier service

Créer le fichier `/etc/systemd/system/certbot.service`
```
[Unit]
Description=Let's Encrypt renewal

[Service]
Type=oneshot
ExecStart=/bin/bash -c "/usr/bin/certbot renew --quiet --agree-tos"
ExecStartPost=/bin/systemctl reload nginx.service
```
## Activer le fichier timer
```
sudo systemctl daemon-reload
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```
