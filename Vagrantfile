# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Kubernetes sürümü
  k8s_version = "1.26.0"
  
  # Sanal makinelerin özellikleri
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # Master node
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/focal64"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    master.vm.provision "shell", path: "scripts/common.sh", args: [k8s_version]
    master.vm.provision "shell", path: "scripts/master.sh", args: [k8s_version]
  end

  # Worker node 1
  config.vm.define "worker1" do |worker|
    worker.vm.box = "ubuntu/focal64"
    worker.vm.hostname = "worker1"
    worker.vm.network "private_network", ip: "192.168.56.11"
    
    worker.vm.provision "shell", path: "scripts/common.sh", args: [k8s_version]
    worker.vm.provision "shell", path: "scripts/worker.sh"
  end

  # Worker node 2
  config.vm.define "worker2" do |worker|
    worker.vm.box = "ubuntu/focal64"
    worker.vm.hostname = "worker2"
    worker.vm.network "private_network", ip: "192.168.56.12"
    
    worker.vm.provision "shell", path: "scripts/common.sh", args: [k8s_version]
    worker.vm.provision "shell", path: "scripts/worker.sh"
  end
end
