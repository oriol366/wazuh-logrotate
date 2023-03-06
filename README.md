# Wazuh Logs Rotator to S3
## What is this?
This container runs periodically to back up all logs in the Wazuh server folder (usually /var/ossec/logs). Uploads them to an S3 bucket and applies a retention policy which removes older logs from the host and passes those files on the S3 bucket to a cooler storage-class.

## Deploy on Docker

The docker folder contains a docker-compose file, missing the AWS IAM credentials.
The file called logrotator contains the cron expression which will execute the backup script.
Inside the docker-compose file, the path /var/ossec/logs is mapped to the same path inside the container, change at will to point to the correct path.

Refer to 'Environment Variables' for info regarding the correct settings.

## Deploy on Kubernetes

It should be deployed within the pod as an additional container.
The file kubernetes/wazuh-master-sts.yaml contains the definition of the extra container.
It can be applied with the command: kubectl patch -f wazuh-master-sts.yaml
Also, there are two more files required for the container to work properly:
wazuh-logrotate-aws-config.yaml: With the AWS IAM credentials needed to access the S3 bucket
wazuh-logrotate-cron-config.yaml: Containing the cron settings for executing the script. By default, it will launch every day at 04:00 AM.

Refer to 'Environment Variables' for info regarding the correct settings.

## Testing

The testing folder includes an extra image build instructions to debug the logrotate process.
You can change the date inside the container to test the script using the environment variable FAKETIME, the format is "dd-mm-yyyy hh:mm:ss", thanks to libfaketime: https://github.com/wolfcw/libfaketime
It also includes two scripts to deploy a debug container:
- preparefolder.sh: Extracts the contents of a file called wazuh-logrotate-test.tar which is expected to contain the logs root folder from the wazuh manager /var/ossec/logs.
- rundebugcontainer.sh: Contains a docker run command with the environment variables ready for debugging. The AWS credentials are missing.

## Environment Variables

DAYS_TO_KEEP: The number of days that the logs will be kept on the host, after that time, all files backed up that day will be deleted and the data in the bucket will change its storage class to the one specified in the Environment Variable OLD_FILES_STORAGE_CLASS
WAZUH_LOGS_PATH: Path mapped inside the container which has the logs from the Wazuh Manager
BUCKET_NAME: Name of the S3 bucket
CLIENT_NAME: This will put the logs on a folder with that name on the root folder of the S3 bucket
AWS_ACCESS_KEY_ID: Access key ID of a cloud user which has privileges on the S3 bucket
AWS_SECRET_ACCESS_KEY: Secret key of the cloud user
AWS_DEFAULT_REGION: Cloud region where the S3 bucket is located
OLD_FILES_STORAGE_CLASS: Storage class that will have files older than DAYS_TO_KEEP in the S3 bucket