#!/bin/bash

set -e

# Create a comma-separated list of our NICs' IP addresses
locals=$(ip -o -4 addr show | sed 's#^.*inet \([0-9.]*\).*#\1#' | xargs echo | sed "s/ /,/g")

# Save the existing umask value before changing it
OLD_UMASK=$(umask)
umask 337     # make sudoers files 440

# Make subsequent file creates readable only by root user/group
cat > /etc/sudoers.d/50_admin_nopass<<-EOF
	%admin ALL=(ALL) NOPASSWD: ALL
	vagrant ALL=(ALL) NOPASSWD: ALL
EOF

# Restore umask
umask $OLD_UMASK

# Updating and Upgrading dependencies.  This has to be done after setting the apt proxy above
# TODO(leeantho) Sometimes apt-update will return a GPG NODATA error the first
# time it is run. If the error occurs run it again and it should work. There
# might be a better way to deal with this issue.
apt-get update -y -qq > /dev/null || apt-get update -y -qq > /dev/null
apt-get upgrade -y -qq > /dev/null

# Install necessary libraries for guest additions and Vagrant NFS Share, and some others :-)
mkdir -p /var/cache/pip
apt-get -y -q install python-pip git ntp git-review firefox xvfb htop tig gitk cifs-utils \
    vim-gtk exuberant-ctags chromium-browser vim-python-jedi meld \
    python-dev python3-dev libmysqlclient-dev \
    nfs-kernel-server nfs-common fortune-mod \
    libffi-dev libssl-dev nodejs nodejs-dev

pip install -U pip
pip install flake8 rstcheck shyaml

gem install gist

groupadd -r admin
usermod -a -G admin vagrant

## Avoid port conflicts between swift and sshd
sed -i '/X11DisplayOffset/ {s/10/100/}' /etc/ssh/sshd_config
service ssh restart

## setup NFS shares for cinder
mkdir /srv/cinder
chown root:vagrant /srv/cinder
cat >>/etc/exports<<-EOF
/srv/cinder        *(rw,sync,crossmnt,no_subtree_check)
EOF
service nfs-kernel-server restart
