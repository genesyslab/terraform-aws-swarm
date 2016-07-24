#!/bin/sh


IP_ADDR=`curl http://169.254.169.254/latest/meta-data/local-ipv4`


docker run -d swarm join --advertise=$$IP_ADDR:2375 consul://${consul_server}:8500
