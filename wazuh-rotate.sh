#!/bin/bash
if [[ -z "{$AWS_ACCESS_KEY_ID}" ]]; then
  echo "Env variable: AWS_ACCESS_KEY_ID not set"
  exit 1
fi
if [[ -z "{$AWS_SECRET_ACCESS_KEY}" ]]; then
  echo "Env variable: AWS_SECRET_ACCESS_KEY not set"
  exit 1
fi
if [[ -z "{$AWS_DEFAULT_REGION}" ]]; then
  echo "Env variable: AWS_DEFAULT_REGION not set"
  exit 1
fi
if [[ -z "{$DAYS_TO_KEEP}" ]]; then
  echo "Env variable: DAYS_TO_KEEP not set"
  exit 1
fi
if [[ -z "{$WAZUH_LOGS_PATH}" ]]; then
  echo "Env variable: WAZUH_LOGS_PATH not set"
  exit 1
fi
if [[ -z "{$BUCKET_NAME}" ]]; then
  echo "Env variable: BUCKET_NAME not set"
  exit 1
fi
if [[ -z "{$CLIENT_NAME}" ]]; then
  echo "Env variable: CLIENT_NAME not set"
  exit 1
fi
if [[ -z "{$OLD_FILES_STORAGE_CLASS}" ]]; then
  echo "Env variable: OLD_FILES_STORAGE_CLASS not set"
  exit 1
fi

days="$((${DAYS_TO_KEEP} + 1))"
path="${WAZUH_LOGS_PATH}"

if  (($days < 1)) || (($days > 30)); then
    echo "DAYS_TO_KEEP should be a number between 1 and 30"
    exit 1
fi

if [ ! -d "$path" ]; then
    echo "WAZUH_LOGS_PATH absolute path doesn't exist"
    exit 1
fi

cd $path

year=$(date +"%Y" -d "-1 day")
month=$(date +"%b" -d "-1 day")
dayMinusOne=$(date +"%d" -d "-1 day")

#Backing up logs from yesterday
/usr/bin/aws s3 cp . s3://${BUCKET_NAME}/${CLIENT_NAME}/ --recursive --exclude "*" --include "*/$year/$month/*$dayMinusOne.*"
if [ $? -ne 0 ]; then
  echo "$(date): ERROR while uploading new logs" >> /home/logrotator/errorMessages.log
  echo "2" > /home/logrotator/monitorExitCode
  exit 2
fi

#Retention Policy
includedFilesRetention="$(date +"%d" -d "-$days days")"

#Moving older files according to $DAYS_TO_KEEP to the designated storage class
/usr/bin/aws s3 mv s3://${BUCKET_NAME}/${CLIENT_NAME}/ s3://${BUCKET_NAME}/${CLIENT_NAME}/$OLD_FILES_STORAGE_CLASS/ --recursive --exclude "*" --include "*$includedFilesRetention.*" --exclude "$OLD_FILES_STORAGE_CLASS/*" --storage-class $OLD_FILES_STORAGE_CLASS
if [ $? -ne 0 ]; then
  echo "$(date): ERROR while changing storage class on S3 old logs" >> /home/logrotator/errorMessages.log
  echo "2" > /home/logrotator/monitorExitCode
  exit 2
fi

#This line removes the same files that were moved to the other storage class
rm */$(date +"%Y" -d "-$days days")/$(date +"%b" -d "-$days days")/*$(date +"%d" -d "-$days days").*

echo "0" > /home/logrotator/monitorExitCode
exit 0