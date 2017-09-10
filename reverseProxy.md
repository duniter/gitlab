# Gitlab pages specificity

Gitlab pages needs to be listening on a specific ip in the docker container.

We need then to use a specific module of nginx to discriminate which sites needs to be sent to gitlab-pages, and which should not. Nginx must be in version at least 1.12.

In `/etc/nginx/nginx.conf` add the following lines:
```
stream {
       map $ssl_preread_server_name $name {
       	   ~.*pages.duniter.org pages;
	         website.duniter.org pages;
           default https_default_backend;
       }
       upstream pages {
           server 73.0.0.10:443;
       }
       upstream https_default_backend {
           server 127.0.0.1:443;
       }
       server {
           listen 91.121.108.84:443;
           proxy_pass $name;
           ssl_preread on;
      }
}
```

Each time a specific domain must be served by gitlab pages in ssl, it must be added in the map, using pages upstream.


File for nginx must be `/etc/nginx/sites-available/git.conf`

```
server {
    listen 80;
    include includes/letsencrypt.conf;
    location / {
        return 301 https://git.duniter.org:443/$request_uri;
    }
}

server {
    server_name git.duniter.org;
    include includes/certificate_git.conf;
    include includes/letsencrypt.conf;
    client_max_body_size 2G;
    location / {
        include /etc/nginx/includes/proxy-to-gitdocker.conf;
    }
}

server {
    listen 80;
    server_name *.pages.duniter.org;
    location / {
        include /etc/nginx/includes/proxy-to-pages.conf;
    }
}

server {
    listen 80;
    server_name registry.duniter.org;
    client_max_body_size 0;
    include includes/certificate_registry.conf;
    include includes/letsencrypt.conf;
    location / {
        include /etc/nginx/includes/proxy-to-registry-gitdocker.conf;
    }
}
server {
    server_name prometheus.duniter.org;
    client_max_body_size 0;
    include includes/certificate_prometheus.conf;
    include includes/letsencrypt.conf;
    location / {
        include /etc/nginx/includes/proxy-to-prometheus-gitdocker.conf;
        auth_basic "Restricted Content";
        auth_basic_user_file /etc/nginx/includes/htpasswd_prometheus;
    }
}

server {
    server_name website.duniter.org;
    listen 80;
    location / {
        include /etc/nginx/includes/proxy-to-pages.conf;
    }
}
```

Note here an example of specific domain used for gitlab pages (website.duniter.org). It is important, because configuration in nginx.conf will only be used for ssl https connections.

File for proxy to main gitlab must be `/etc/nginx/includes/proxy-to-gitdocker.conf`

```
proxy_redirect off;
proxy_set_header Host $host:$server_port;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Port $server_port;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_pass https://localhost:8443/;
send_timeout 600;
proxy_read_timeout 600;
proxy_connect_timeout 600;
```


File for proxy to registry gitlab must be `/etc/nginx/includes/proxy-to-registry-gitdocker.conf`

```
proxy_redirect off;
proxy_set_header Host $host:$server_port;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Port $server_port;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_pass https://localhost:5043/;
send_timeout 600;
proxy_read_timeout 600;
proxy_connect_timeout 600;
```
File for proxy to registry gitlab must be `/etc/nginx/includes/proxy-to-prometheus-gitdocker.conf`

```
proxy_redirect off;
proxy_set_header Host $host:$server_port;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Port $server_port;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_pass http://localhost:9090/;
send_timeout 600;
proxy_read_timeout 600;
proxy_connect_timeout 600;
```

Copy certificates

```
cp /etc/letsencrypt/live/git.duniter.org/fullchain.pem /var/gitlab/config/ssl/git.duniter.org.crt
cp /etc/letsencrypt/live/git.duniter.org/privkey.pem /var/gitlab/config/ssl/git.duniter.org.key
cp /etc/letsencrypt/live/registry.duniter.org/fullchain.pem /var/gitlab/config/ssl/registry.duniter.org.crt
cp /etc/letsencrypt/live/registry.duniter.org/privkey.pem /var/gitlab/config/ssl/registry.duniter.org.key
cp /etc/letsencrypt/live/prometheus.duniter.org/fullchain.pem /var/gitlab/config/ssl/prometheus.duniter.org.crt
cp /etc/letsencrypt/live/prometheus.duniter.org/privkey.pem /var/gitlab/config/ssl/prometheus.duniter.org.key
```

In the certbot service, we should copy the certificates so it becomes:

```
[Unit]
Description=Let's Encrypt renewal

[Service]
Type=oneshot
ExecStart=/bin/bash -c "/usr/bin/certbot renew --quiet --agree-tos;cp /etc/letsencrypt/live/git.duniter.org/fullchain.pem /var/gitlab/config/ssl/git.duniter.org.crt;cp /etc/letsencrypt/live/git.duniter.org/privkey.pem /var/gitlab/config/ssl/git.duniter.org.key;cp /etc/letsencrypt/live/registry.duniter.org/fullchain.pem /var/gitlab/config/ssl/registry.duniter.org.crt;cp /etc/letsencrypt/live/registry.duniter.org/privkey.pem /var/gitlab/config/ssl/registry.duniter.org.key;cp /etc/letsencrypt/live/prometheus.duniter.org/fullchain.pem /var/gitlab/config/ssl/prometheus.duniter.org.crt;cp /etc/letsencrypt/live/prometheus.duniter.org/privkey.pem /var/gitlab/config/ssl/prometheus.duniter.org.key"
ExecStartPost=/bin/systemctl reload nginx.service
```
