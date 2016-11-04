#!/bin/bash

# This script uses packer to create vagrant box images that have devstack 
# pre-installed and all requirements installed. 
# The script will copy the built box to ~/images/vagrant 
# 
# This solution supports several "flavors":
#   all  - starts all devstack processes (sahara, trove, etc).
#   base - starts only the default devstack processes (nova, glance, keystone, cinder)
#   min  - starts only the default devstack processes, effectively the same as base
#
# Usage:
#    ./build.sh [flavor..]
#

IMAGES_DIR="$HOME/images/vagrant"

if [ ! -d "$IMAGES_DIR" ]
then
    echo "Please create '$IMAGES_DIR' to store the vagrant box images."
    exit 1
fi

# Build the following by default
flavors=${@:-"all"}

if ! grep -q -E '(vmx|svm)' /proc/cpuinfo ; then
   printf "Virtualization must be enabled" >&2
   exit 1
fi

# Default BUILD_ID to current date/time if not running from Jenkins
BUILD_ID=${BUILD_ID:-$(date '+%Y-%m-%d_%H-%M-%S')}

export PACKER_LOG=true

# Build requested flavor(s)
for flavor in $flavors ; do

    echo "Building $flavor flavor..."

    # Clean up from previous run
    rm -rf output-qemu

    cat > files/VERSION.txt <<VERSION
flavor: $flavor
build_id: $BUILD_ID
VERSION

    packer build -var "flavor=$flavor" packer.json

    if [[ $? -eq 0 ]] ; then
        # Rename resulting file to be current date/time (or BUILD_ID if running from
        # jenkins)
        echo "Moving ${BUILD_ID}_${flavor}.box to $IMAGES_DIR"
        mv packer_qemu_libvirt.box $IMAGES_DIR/${BUILD_ID}_${flavor}.box
    fi
done
