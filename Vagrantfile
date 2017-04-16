Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'
  config.vm.network 'private_network', type: 'dhcp', bridge: 'wlp2s0'

  # Just install Python for now
  config.vm.provision 'shell' do |shell|
    shell.inline = <<EOF
  if ! `command -v python` ; then
    sudo apt-get update && sudo apt-get install -y python
  fi
EOF
  end

  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = 'playbook.yml'
    ansible.verbose = true
  end
end
