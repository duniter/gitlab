FROM library/ubuntu:16.04
MAINTAINER Florian Thöni <florian.thoni@floth.fr>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y curl apt-transport-https ca-certificates
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list

RUN apt-get update
RUN apt-get install -y docker-engine python-pip git

RUN pip install docker-compose

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
