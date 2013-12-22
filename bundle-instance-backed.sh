#!/bin/bash

NAME=$1
ACCOUNT=$2

mkdir bundle
ec2-bundle-image -r x86_64 -d ~/bundle -p $NAME -u $ACCOUNT \
  -k /vagrant/keys/private-key.pem  \
  -c /vagrant/keys/cert.pem \
  --kernel aki-52a34525 \
  --image /rootfs.loop
