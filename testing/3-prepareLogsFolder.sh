#!/bin/bash
sudo rm -rf $PWD/logs
mkdir $PWD/logs && chown 101:101 $PWD/logs
tar xvf $PWD/${LOGS_TAR_FILE} -C $PWD/logs
sudo chown 101:101 $PWD/logs/* -R
