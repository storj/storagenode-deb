FROM debian:buster

RUN echo "deb [trusted=yes] http://deb.debian.org/debian buster-backports main" > /etc/apt/sources.list.d/backports.list
RUN apt-get -q update
RUN apt-get install -q -y build-essential devscripts
RUN apt-get install -q -y debhelper/buster-backports
