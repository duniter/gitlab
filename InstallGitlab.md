# Install docker-compose
As root launch
```
curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
```


Then
```
sudo chmod +x /usr/local/bin/docker-compose
```


# Install gitlab
## Docker compose File
Create docker-compose.yml file in a gitlab folder (eg /build/gitlab/docker-compose.yml)
Content is as follow :
```
version: '2'
services:
    gitlab:
        image: $GITLAB_IMAGE
        domainname: duniter.org
        hostname: git-sandbox
        volumes:
            - "/srv/gitlab/config:/etc/gitlab"
            - "/srv/gitlab/logs:/var/log/gitlab"
            - "/srv/gitlab/data:/var/opt/gitlab"
        ports:
            - "2222:22"
            - "8443:443"
            - "5043:5043"
        restart: always
```

## Mapped directories
Still as root user, create gitlab directory in /srv (in production real worls, this may be adapted) and give proper rights to it.
```
mkdir /srv/gitlab
chmod -R 755 /srv/gitlab
```

## Ports used
This docker-compose file will map port 2222 of host to 22 of the machine for git+ssh, 8443 to 443 for https (no http) and 5043 to 5043 for docker images.

## Start at once gitlab
Adapt the following gitlab image version with current you want to install :
```
GITLAB_IMAGE=gitlab/gitlab-ce:9.1.2-ce.0 docker-compose up -d
```


Check that gitlab is running :
```
docker ps -a
```

Wait for end of first configuration. You can follow using
```
docker logs -f gitlab_gitlab_1
```

You will understand it is finished when you will see logs from standard process like
```
2017-06-05_14:31:28.78329 ::1 - - [05/Jun/2017:14:31:28 UTC] "GET /database HTTP/1.1" 200 37921
2017-06-05_14:31:28.78338 - -> /database
```

# Configure gitlab
## Open gitlab configuration file
Please refer to gitlab.rb file (TODO:link)

This file must be on server at /srv/gitlab/config/gitlab.rb (in the docker container it is at /etc/gitlab/gitlab.rb)
Enter in the docker container
```
sudo docker exec -it gitlab_gitlab_1 /bin/bash
```
in the docker container reconfigure gitlab
```
gitlab-ctl reconfigure
```


# Configure the reverse proxy
## Configure the dns
Create CNAME or A entry for the wanted adress (here git-sandbox.duniter.org
)
Apply letsencrypt.md (TODO:link)

File for nginx must be `/etc/nginx/sites-available/git.conf`
```
server {
    listen 80;
    server_name git-sandbox.duniter.org;
#    include includes/certificate_git.conf;
     include includes/letsencrypt.conf;
     location / {
       		include /etc/nginx/includes/proxy-to-gitdocker.conf;
		 }
}

```

File for proxy must be `/etc/nginx/includes/proxy-to-gitdocker.conf`

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

Copy certificates

```
cp /etc/letsencrypt/live/git-sandbox.duniter.org/fullchain.pem /srv/gitlab/config/ssl/git-sandbox.duniter.org.crt
cp /etc/letsencrypt/live/git-sandbox.duniter.org/privkey.pem /srv/gitlab/config/ssl/git-sandbox.duniter.org.key
```

In the certbot service, we should copy the certificates so it becomes:

# Create an oauth application
Follow this guide :
https://docs.gitlab.com/ce/integration/github.html

# First connection
At first connection, you will be asked to create a password for admin user.

Once done, create the first user, set him administrator rights, disconnect, connect as this user and then block original admin user (security purpose)
