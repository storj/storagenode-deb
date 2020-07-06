FROM debian:buster

RUN apt-get -q update && apt-get install -q -y build-essential devscripts debhelper
