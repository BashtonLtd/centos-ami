# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # This Vagrantfile should work with Virtualbox and LXC
  config.vm.provider "virtualbox" do |vb, config|
    config.vm.box = "centos64"
    config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-vbox4210.box"
  end

  config.vm.provider "lxc" do |lxc, config|
    config.vm.box = "centos65-lxc"
    config.vm.box_url = "https://dl.dropboxusercontent.com/s/x1085661891dhkz/lxc-centos6.5-2013-12-02.box"
  end

  config.vm.box = "centos64"

  config.vm.provision "shell", path: "build-centos-box.sh"

  config.cache.auto_detect = true
  config.cache.enable_nfs  = true

end
