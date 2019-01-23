#!/bin/bash
if [[ "$1" == "" ]] ; then
        lan_ip=`ip addr | grep inet | grep -v inet6 | grep -v 127.0.0.1 | awk '{print $2}' | awk -F '/' '{print $1}'`
        echo "exec distccd --daemon --log-stderr --no-detach --allow  $lan_ip"
        distccd --daemon --log-stderr --no-detach --allow $lan_ip
        exit 0
fi

echo "exec distccd --daemon --log-stderr --no-detach --allow $1"
distccd --daemon --log-stderr --no-detach --allow $1
