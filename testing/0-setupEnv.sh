#!/bin/bash

source .env

docker network create ${DOCKER_NETWORK}

docker build -t oriol366/logrotate-testing .