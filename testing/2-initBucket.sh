#!/bin/bash

docker exec ${MINIO_HOST} curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o /root/minio-binaries/mc 
docker exec ${MINIO_HOST} chmod +x /root/minio-binaries/mc 
docker exec ${MINIO_HOST} /root/minio-binaries/mc alias set minio http://localhost:9000 ${ACCESS_KEY_ID} ${SECRET_ACCESS_KEY}
docker exec ${MINIO_HOST} /root/minio-binaries/mc mb minio/${BUCKET_NAME}

