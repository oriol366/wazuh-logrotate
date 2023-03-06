FROM alpine:3.17
RUN apk add --no-cache python3 py3-pip && \
    apk add --no-cache bash coreutils && \
    pip install awscli && \
    rm -rf /var/cache/apk/* && \
    adduser -u 101 -h /home/logrotator -D logrotator
COPY wazuh-rotate.sh /wazuh-rotate.sh
RUN chown logrotator:logrotator /wazuh-rotate.sh && \
    chmod 750 /wazuh-rotate.sh && \
    echo "0" > /home/logrotator/monitorExitCode && \
    chown logrotator:logrotator /home/logrotator/monitorExitCode
CMD crond -f -c /cronfiles