# frozen_string_literal: true

# vim: set syntax=ruby:
# rubocop:disable Metrics/BlockLength
# rubocop:disable Layout/HeredocIndentation
Vagrant.configure('2') do |config|
#RAM has to be bumped up due of precompile assets silently failing with just 1GB of RAM
#https://github.com/rails/webpacker/issues/955
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
   end

  config.vm.define 'bare', primary: true do |bare|
#Used for RHEL testing
#    bare.vm.box = "geerlingguy/rockylinux8"
    bare.vm.box = 'ubuntu/focal64'
#    bare.vm.network 'private_network', ip: '192.168.56.12'
    bare.vm.network 'private_network', type: 'dhcp'
    bare.vm.provision 'ansible_local' do |ansible|
      ansible.playbook = 'bare/playbook.yml'
      ansible.extra_vars = {
        mastodon_db_password: 'CHANGEME',
        mastodon_host: 'mastodon.local',
        redis_pass: 'CHANGEME',
        local_domain: 'mastodon.local',
        db_pass: 'CHANGEME',
        disable_letsencrypt: 'true'
      }
      ansible.verbose = true
      ansible.skip_tags = 'letsencrypt'
    end

    %w[Gemfile Gemfile.lock spec .rspec].each do |file|
      bare.vm.provision 'file',
                        source: file,
                        destination: file
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = false
      shell.inline = <<SHELL
      # Ruby is installed as mastodon user, that user has no permission to run ufw
      # because of that we do this little workaround
     #sudo ##sudo ufw status 2>&1 > /home/vagrant/ufw_result.txt
     #sudo #ssudo -u mastodon -i /bin/sh <<MASTODO 
     #sudo systemctl stop firewalld
     #sudo systemctl disable firewalld
      #cd /home/vagrant
      #bundle install
      #bundle exec rubocop
      #bundle exec rspec
#MASTODON_BLOCK
SHELL
    end
  end

  config.vm.define 'docker' do |docker|
    docker.vm.box = 'ubuntu/bionic64'
    docker.vm.network 'private_network', type: 'dhcp'
    docker.vm.provision 'ansible_local' do |ansible|
      ansible.playbook = 'docker/playbook.yml'
      ansible.verbose = true
    end
  end
end
# rubocop:enable Layout/HeredocIndentation
# rubocop:enable Metrics/BlockLength



