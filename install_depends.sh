#!/bin/bash

if [ -f /etc/redhat-release ]; then
  yum -y install distcc distcc-server ccache
fi

if [ -f /etc/lsb-release ]; then
  apt-get -y install distcc distcc-server ccache
fi
