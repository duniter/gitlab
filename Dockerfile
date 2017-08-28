FROM library/ubuntu:16.04
MAINTAINER Florian Thöni <florian.thoni@floth.fr>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update; \
   apt-get install -y curl apt-transport-https ca-certificates; \
   apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D; \
   echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list; \
   apt-get update; \
   apt-get install -y docker-engine python-pip git; \
   apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN  pip install docker-compose

RUN curl -OL https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2
RUN tar -xf linux-amd64-github-release.tar.bz2
RUN mv bin/linux/amd64/github-release /usr/bin
