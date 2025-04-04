#!/bin/bash

#!/bin/bash
set -euo pipefail

# Check for required compilers
if ! command -v gcc &> /dev/null || ! command -v g++ &> /dev/null; then
    echo "Error: gcc and g++ must be installed first" >&2
    exit 1
fi

# Install dependencies with sudo and error handling
if [ -f /etc/redhat-release ]; then
    sudo yum -y install distcc distcc-server ccache bc || {
        echo "Failed to install packages via yum" >&2
        exit 1
    }
elif [ -f /etc/lsb-release ]; then
    sudo apt-get -y install distcc distcc-server ccache bc || {
        echo "Failed to install packages via apt-get" >&2 
        exit 1
    }
elif [ -f /etc/arch-release ]; then
    sudo pacman -Syu --noconfirm distcc ccache bc || {
        echo "Failed to install packages via pacman" >&2
        exit 1
    }
else
    echo "Unsupported package manager" >&2
    exit 1
fi

# Configure distcc
echo "DISTCCD_OPTS=\"--allow 192.168.0.0/16 --log-file=/var/log/distccd.log\"" | sudo tee /etc/default/distccd >/dev/null
