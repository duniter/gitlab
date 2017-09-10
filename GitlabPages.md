# Gitlab Pages
## Let's encrypt certificates
Please refer to (reverseProxy.md)[./reverseProxy.md]

We use the following script to create and renew certificates for specific domains in gitlab pages :
https://framagit.org/framasoft/lets-encrypt-gitlab-pages

Adapt lepages.pl with the following lines (around end of file) in order to restart gitlab-pages inside the docker container:

```
my @args = ('docker', 'exec', '-it', 'gitlab_gitlab_1', 'gitlab-ctl', 'restart', 'gitlab-pages');
```

Then schedule the script to be runned every minutes:
```
* * * * * /opt/lepages/lepages
```
