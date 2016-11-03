packer-devstack-vagrant
=======================

Create an Ubuntu 16.04 vagrant box with packer that has devstack installed on
it, as well as all of its prerequisites.

### Usage
```
$ git clone https://github.com/hemna/packer-devstack-vagrant
$ cd packer-devstack-vagrant
$ ./build.sh
```

### Dependencies
* [KVM](http://www.linux-kvm.org/page/Main_Page)
* [QEMU](http://wiki.qemu.org/Main_Page)
* [Vagrant libvirt](https://github.com/pradels/vagrant-libvirt)
* [Packer](http://www.packer.io)
