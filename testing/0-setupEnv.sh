#!/bin/bash

source .env

docker network create minio

docker build -t oriol366/logrotate-testing .