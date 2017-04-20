# rubocop:disable Metrics/BlockLength
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'
  config.vm.network 'private_network', type: 'dhcp'

  # Just install Python for now
  config.vm.provision 'shell' do |shell|
    shell.privileged = true
    shell.inline = <<EOF
  sudo apt-get update
  for package in python ruby-dev ruby-bundler ; do
    if ! `dpkg -l ${package}` ; then
      sudo apt-get install -y --no-install-recommends ${package}
    fi
  done
EOF
  end

  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = 'playbook.yml'
    ansible.verbose = true
  end

  config.vm.provision 'file',
                      source: 'Gemfile',
                      destination: 'Gemfile'
  config.vm.provision 'file',
                      source: 'Gemfile.lock',
                      destination: 'Gemfile.lock'
  config.vm.provision 'file',
                      source: 'spec',
                      destination: 'spec'

  config.vm.provision 'shell' do |shell|
    shell.privileged = false
    shell.inline = <<EOF
    bundle install --deployment
    bundle exec rubocop
    bundle exec rspec
EOF
  end
end
# rubocop:enable Metrics/BlockLength
