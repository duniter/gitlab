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

networks:
    pages:
        ipam:
            driver: default
            config:
                - subnet: 73.0.0.0/16
                  ip_range: 73.0.0.0/24
                  gateway: 73.0.0.254
    gitlab:
        ipam:
            driver: default
            config:
                - subnet: 74.0.0.0/16
                  ip_range: 74.0.0.0/24
                  gateway: 74.0.0.254

services:
    gitlab:
        image: $GITLAB_IMAGE
        domainname: duniter.org
        hostname: git
        networks:
            pages:
                ipv4_address: 73.0.0.10
            gitlab:
                ipv4_address: 74.0.0.10
        volumes:
            - "/var/gitlab/config:/etc/gitlab"
            - "/var/gitlab/logs:/var/log/gitlab"
            - "/var/gitlab/data:/var/opt/gitlab"
            - "/var/gitlab/run:/var/run"
            - "/run/gitlab:/run"
        ports:
            - "22:22"
        restart: always
```

Noticed that /run/gitlab is created in a tmpfs because it is recommended to map /run in docker omnibus gitlab to a tmpfs filesystem.

Moreover, we use specific ip adresses to be able later to use gitlab pages on a dedicated ip.

Create `/run/gitlab/sshd` and set rights to 0550

## Mapped directories
Still as root user, create gitlab directory in /var (in production, this may be adapted) and give proper rights to it.

```
mkdir /var/gitlab
chmod -R 755 /var/gitlab
mkdir /run/gitlab
```
Create `/run/gitlab/sshd` and set rights to 0550

## Ports used
This docker-compose file will map port 22 of host to 22 of the docker for git+ssh, 443, not mapped for https (no http) and 5043, not mapped for docker images and 9090 not mapped for prometheus.
Not mapped ports will be redirected directly by nginx to the needed ips.

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
Please refer to [gitlab.rb](./gitlab.rb) file

This file must be on server at /var/gitlab/config/gitlab.rb (in the docker container it is at /etc/gitlab/gitlab.rb)
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
Create CNAME or A entry for the wanted adress (here git.duniter.org and registry.duniter.org and prometheus.duniter.org)
Apply [letsencrypt.md](./letsencrypt.md)

Please refer to [reverseProxy.md](./reverseProxy.md)

# Create an oauth application
Follow this guide :
https://docs.gitlab.com/ce/integration/github.html

# First connection
At first connection, you will be asked to create a password for admin user.

Once done, create the first user, (I recommand to do it by github connexion) set him administrator rights, disconnect, connect as this user and then block original admin user (security purpose)
