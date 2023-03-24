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

cd $WAZUH_LOGS_PATH

faketimenotset="true"
if [ -n "${FAKETIME}" ]; then
  faketime="${FAKETIME}"
  faketimenotset="false"
fi
limitDate=$(date -d "-$days days" +%s)
unset FAKETIME

standardBucketFiles=$(aws s3api list-objects-v2 --bucket ${BUCKET_NAME} --prefix ${CLIENT_NAME} --query 'Contents[?StorageClass==`STANDARD` && ends_with(Key, `$(echo $HOSTNAME | cut -d'-' -f3,4)`)][Key]' --output text --endpoint-url="http://minio:9000")
bucketFiles=$(echo "${standardBucketFiles//${CLIENT_NAME}/.}")
bucketFiles=$(echo "${bucketFiles//-$(echo ${HOSTNAME} | cut -d'-' -f3,4)/}")
if [ "$bucketFiles" = "None" ]; then
  bucketFiles=" "
fi

localFiles=$(find . -type f -mindepth 3)

#-1 -> SUPRESS unique lines in file1   -2 -> SUPRESS unique lines in file2
#Files present only on local host
comm -13 <(echo "${bucketFiles}" | tr ' ' '\n' | sort) <(echo "${localFiles}" | tr ' ' '\n' | sort) | while read line ; do
  echo "Testing file ${line}"
  year=$(echo "${line}" | cut -d'/' -f3)
  month=$(echo "${line}" | cut -d'/' -f4)
  day=$(echo "${line}" | cut -d'.' -f2 | awk -F '-' '{print $NF}')

  if [ "${faketimenotset}" != "true" ]; then
    export FAKETIME=${faketime}
  fi
  if [[ ${day} == "$(date +%d)" && ${month} == "$(date +%b)" && ${year} == "$(date +%Y)" ]]; then
    echo "Skipping file ${line}"
    continue
  else
    echo "NOT skipped file ${line}"
  fi
  dateFile=$(date -d "$day-$month-$year" +%s)
  unset FAKETIME
  # Substitute the first dot with the client name to match the bucket structure
  dest=$(echo "${line/./${CLIENT_NAME}}")
  dest="${dest}-$(echo $HOSTNAME | cut -d'-' -f3,4)"
  # if file is older than limit date is moved to the bucket with cheaper storage class and deleted from local storage
  if [ "$dateFile" -le "$limitDate" ]; then
    echo "File ${line} is older"
    #"${dest%$(basename "$dest")}"
    /usr/bin/aws s3api put-object --body ${line} --bucket ${BUCKET_NAME} --key ${dest} --storage-class $OLD_FILES_STORAGE_CLASS --endpoint-url="http://minio:9000"
    if [ $? -ne 0 ]; then
      echo "$(date): ERROR (1) while uploading log file: ${line}" >> /home/logrotator/errorMessages.log
      echo "2" > /home/logrotator/monitorExitCode
      exit 2
    fi
    rm ${line}
  else
    echo "File ${line} is NOT older"
    /usr/bin/aws s3api put-object --body ${line} --bucket ${BUCKET_NAME} --key ${dest} --endpoint-url="http://minio:9000"
    if [ $? -ne 0 ]; then
      echo "$(date): ERROR (2) while uploading log file: ${line}" >> /home/logrotator/errorMessages.log
      echo "2" > /home/logrotator/monitorExitCode
      exit 2
    fi
  fi
done

#Files in both locations with STANDARD storage class
comm -12 <(echo "${bucketFiles}" | tr ' ' '\n' | sort) <(echo "${localFiles}" | tr ' ' '\n' | sort) | while read line ; do
  echo "Checking ${line} which is in both locations"
  year=$(echo "${line}" | cut -d'/' -f3)
  month=$(echo "${line}" | cut -d'/' -f4)
  day=$(echo "${line}" | cut -d'.' -f2 | awk -F '-' '{print $NF}')

  if [ "${faketimenotset}" != "true" ]; then
    export FAKETIME=${faketime}
  fi
  if [[ ${day} == "$(date +%d)" && ${month} == "$(date +%b)" && ${year} == "$(date +%Y)" ]]; then
    echo "Skipping file ${line}"
    continue
  fi
  dateFile=$(date -d "$day-$month-$year" +%s)
  unset FAKETIME
  
  # if file is older than limit date its storage class changes to a cheaper one and deleted from local storage
  if [ "$dateFile" -le "$limitDate" ]; then
    echo "File ${line} is older"
    dest=$(echo "${line/./${CLIENT_NAME}}")
    dest="${dest}-$(echo $HOSTNAME | cut -d'-' -f3,4)"
    /usr/bin/aws s3api copy-object --copy-source ${BUCKET_NAME}/${dest} --bucket ${BUCKET_NAME} --key ${dest} --storage-class $OLD_FILES_STORAGE_CLASS --endpoint-url="http://minio:9000"
    if [ $? -ne 0 ]; then
      echo "$(date): ERROR (3) while changing storage class from file ${line}" >> /home/logrotator/errorMessages.log
      echo "2" > /home/logrotator/monitorExitCode
      exit 2
    fi
    rm ${line}
  fi
done
