#!/bin/bash

flavor=${1:-base}

set -e

# Install vagrant ssh keys
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
# Old location
# wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
wget 'http://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 ~/.ssh/authorized_keys
chown -R vagrant ~/.ssh
cd

export OS_USERNAME="admin"
export OS_TENANT_NAME="admin"
export OS_AUTH_URL="http://localhost:35357/v2.0"
export OS_PASSWORD="openstack"

#DEVSTACK_REPO=http://csim-gitlab.rose.hp.com/openstack/devstack.git
# Our DNS is hosed for the time being due to the HP -> HPE split.  
DEVSTACK_REPO=http://github.com/openstack-dev/devstack.git
DEVSTACK_BRANCH=${DEVSTACK_BRANCH:-master}

# Check out devstack
git clone ${DEVSTACK_REPO} -b ${DEVSTACK_BRANCH}

cp /tmp/VERSION.txt $HOME

cd devstack

# Copy local devstack customizations
cp /tmp/local.conf.${flavor} local.conf

# Tweak stack.sh to install all prerequisites without configuration, then exit

sed -r -i -e '/configure_/ s/^/#/' \
          -e '/cleanup_nova/ s/^/#/' \
          -e '/init_(CA|cert)/ s/^/#/' \
          -e '/init_cert/ atrue' \
          -e '/# Phase: install/ a \
              exit' stack.sh

echo "Installing prerequisites..."
VERBOSE=true ./stack.sh

# revert change to stack script
git checkout stack.sh

# Prep /etc/cinder for nfs
sudo mkdir -p /etc/cinder
sudo chmod 777 /etc/cinder
sudo chown root:vagrant /etc/cinder
sudo touch /etc/cinder/nfsshares
sudo chown root:vagrant /etc/cinder/nfsshares
sudo chmod 666 /etc/cinder/nfsshares
sudo cat > /etc/cinder/nfsshares<<EOF
localhost:/srv/cinder
EOF
