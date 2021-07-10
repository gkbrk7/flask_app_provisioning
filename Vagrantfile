Vagrant.configure("2") do |config|
  
      config.vm.box = "ubuntu/xenial64"
      # config.vm.hostname = "flaskapp.local"
      config.vm.network "private_network", ip: "192.168.2.15"
      config.vm.network "forwarded_port", guest: 80, host: 8080
      config.vm.provision "shell", path: "provision.sh"
end
