#!/bin/bash
docker run -it --rm -v $PWD/cronfiles:/cronfiles -v $PWD/logs:/var/ossec/logs \
    -e DAYS_TO_KEEP=2 -e WAZUH_LOGS_PATH=/var/ossec/logs -e BUCKET_NAME=<BUCKET_NAME> \
    -e CLIENT_NAME=testing -e AWS_ACCESS_KEY_ID=############# \
    -e AWS_SECRET_ACCESS_KEY=############ \
    -e AWS_DEFAULT_REGION=eu-central-1 -e OLD_FILES_STORAGE_CLASS=STANDARD_IA \
    logrotate-testing
