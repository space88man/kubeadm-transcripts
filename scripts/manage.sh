#!/bin/bash
## manage.sh
## This is a nuke-n-pave script.
## It stops and deletes all docker containers and 
## removes all configuration by kubeadm

if [ $1 = 'cleanup' ]; then
   docker rm $(docker ps -a --format '{{.Names}}')
   exit 0
fi

if [ $1 = 'stop' ]; then
   docker stop $(docker ps --format '{{.Names}}')
   exit 0
fi

if [ $1 = 'wipe' ]; then
   umount /var/lib/kubelet/*/*/*/*/*
   rm -rf /var/lib/etcd/* /etc/kubernetes/* /var/lib/kubelet/*
   exit 0
fi

echo "Usage: manage.sh cleanup|stop|wipe"
echo "stop: stops all docker containers"
echo "cleanup: removes ALL docker containers"
echo "wipe: removes all kubernetes configuration set up by kubeadm"
