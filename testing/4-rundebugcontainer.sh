#!/bin/bash

docker run -it --rm -v $PWD/cronfiles:/cronfiles -v $PWD/logs:/var/ossec/logs --hostname=${LOGROTATE_HOST} \
    -e DAYS_TO_KEEP=2 -e WAZUH_LOGS_PATH=/var/ossec/logs -e BUCKET_NAME=${BUCKET_NAME} \
    -e CLIENT_NAME=${CLIENT_NAME} -e AWS_ACCESS_KEY_ID=${ACCESS_KEY_ID} \
    -e AWS_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY} \
    -e AWS_DEFAULT_REGION=${S3_REGION} -e OLD_FILES_STORAGE_CLASS=${OLD_FILES_STORAGE_CLASS} \
    --network=${DOCKER_NETWORK} \
    logrotate-testing

# try doing: export FAKETIME="2022-12-31 12:00:00" and /wazuh-rotate.sh