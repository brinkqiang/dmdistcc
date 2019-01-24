#!/bin/bash
if [[ "$1" == "" ]] ; then
        echo "exec distccd --daemon --log-stderr --no-detach --allow 0.0.0.0/0"
        distccd --daemon --log-stderr --no-detach --allow 0.0.0.0/0
        exit 0
fi

echo "exec distccd --daemon --log-stderr --no-detach --allow $1"
distccd --daemon --log-stderr --no-detach --allow $1
