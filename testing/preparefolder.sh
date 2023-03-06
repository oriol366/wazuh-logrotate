#!/bin/bash
sudo rm -rf $PWD/logs/*
tar xvf $PWD/wazuh-logrotate-test.tar -C $PWD/logs
sudo chown 101:101 $PWD/logs/* -R
