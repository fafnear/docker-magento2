#!/usr/bin/env bash

for image in $(docker images --format "{{ .ID }}")
do
    #docker image rm -f $image
    echo $image
done

for container in $(docker ps -a --format "{{ .ID }}")
do
    docker rm $container
done

for volume in $(docker volume list --format "{{ .Name }}")
do
    docker volume rm $volume
done