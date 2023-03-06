FROM oriol366/wazuh-logrotate:latest
RUN apk add gcc make git libc-dev
WORKDIR /
RUN git clone https://github.com/wolfcw/libfaketime.git
WORKDIR /libfaketime/src
RUN make install
ENV LD_PRELOAD=/usr/local/lib/faketime/libfaketime.so.1
WORKDIR /
COPY wazuh-rotate-testing.sh /wazuh-rotate.sh
RUN chown 101:101 /wazuh-rotate.sh && chmod 750 /wazuh-rotate.sh
CMD ["/bin/bash"] 
