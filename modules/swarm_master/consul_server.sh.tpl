#!/bin/sh

#TODO fail if these aren't here


docker run -d -h node${index} -v /var/consul:/data \
   -p 8300:8300 \
   -p 8301:8301 \
   -p 8301:8301/udp \
   -p 8302:8302 \
   -p 8302:8302/udp \
   -p 8400:8400 \
   -p 8500:8500 \
   progrium/consul -server -advertise ${address} \
     -bootstrap-expect ${num_servers} -join ${root_address}
