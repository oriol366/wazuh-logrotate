#!/bin/bash

docker run --rm -v ${PWD}/minio_storage:/data -e MINIO_REGION=${S3_REGION} -e MINIO_ROOT_USER=${ACCESS_KEY_ID} \
-e MINIO_ROOT_PASSWORD=${SECRET_ACCESS_KEY} --network=${DOCKER_NETWORK} -p 9001:9001 --name=${MINIO_HOST} \
 minio/minio:latest server --console-address ":9001" /data

