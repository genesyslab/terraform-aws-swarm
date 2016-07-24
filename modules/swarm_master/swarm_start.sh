#!/bin/sh


IP_ADDR=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

docker run --name=swarmmanager -d -p 4000:4000 swarm manage -H :4000 \
 --replication --advertise $IP_ADDR:4000 \
 consul://$IP_ADDR:8500
