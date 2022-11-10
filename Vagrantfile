goss_version = '0.3.16'
install_goss = <<~SHELL
  echo "The target is \$TARGET" && \
  curl -Lo /tmp/goss https://github.com/aelsabbahy/goss/releases/download/v#{goss_version}/goss-linux-amd64 && \
  echo "827e354b48f93bce933f5efcd1f00dc82569c42a179cf2d384b040d8a80bfbfb  /tmp/goss" | sha256sum -c --strict - && \
  sudo install -m0755 -o root -g root /tmp/goss /usr/bin/goss && \
  rm /tmp/goss
  cd /vagrant
  sudo -E goss --vars vars.yaml validate
SHELL

#Fix for https://github.com/mastodon/mastodon-ansible/pull/33#issuecomment-1126071199
postgres_use_md5 = <<~SHELL
sudo sed -i 's/host\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\s127.0.0.1\/32\s\s\s\s\s\s\s\s\s\s\s\sident/host    all             all             127.0.0.1\/32                 md5/g' /var/lib/pgsql/data/pg_hba.conf
sudo sed -i 's/host\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\s::1\/128\s\s\s\s\s\s\s\s\s\s\s\s\s\s\s\s\sident/host    all             all             ::1\/128                 md5/g' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
SHELL

ansible_extra_vars = {
  mastodon_db_password: 'CHANGEME',
  mastodon_host: 'mastodon.local',
  redis_pass: 'CHANGEME',
  local_domain: 'mastodon.local',
  disable_letsencrypt: 'true'
}

Vagrant.configure('2') do |config|
  # RAM has to be bumped up due of precompile assets silently failing with just 1GB of RAM
  # https://github.com/rails/webpacker/issues/955
  config.vm.provider 'virtualbox' do |vb|
    vb.memory = '4096'

    # We need to disable nested virtualization since GitHub Actions doesn't support it
    # https://github.com/actions/virtual-environments/issues/183#issuecomment-610723516
    #
    # I have disabled this for now since we are running our tests on macOS (for now) which has "native" Vagrant support on GH
    #
    # %w[hwvirtex vtxvpid vtxux].each do |instruction|
    #   vb.customize ["modifyvm", :id, "--#{instruction}", "off"]
    # end if ENV['CI'] == "true"
  end
  config.vm.provider 'vmware_fusion' do |vb|
    vb.memory = '4096'
  end

  [
    {
      name: 'focal',
      primary: true,
      autostart: true
    },
    {
      name: 'jammy',
      primary: false,
      autostart: false
    }
  ].each do |d|
    config.vm.define d[:name], primary: d[:primary], autostart: d[:autostart] do |bare|
      bare.vm.box = "ubuntu/#{d[:name]}64"
      bare.vm.network 'private_network', type: 'dhcp'
      bare.vm.provision 'ansible_local' do |ansible|
        ansible.playbook = 'bare/playbook.yml'
        ansible.extra_vars = ansible_extra_vars
        ansible.verbose = true
        ansible.skip_tags = 'letsencrypt'
      end

      bare.vm.provision 'shell' do |shell|
        shell.privileged = false
        shell.env = {
          'TARGET' => 'ubuntu'
        }
        shell.inline = install_goss
      end
    end
  end

  config.vm.define 'rhel8', autostart: false do |bare|
    bare.vm.box = 'rockylinux/8'
    bare.vm.network 'private_network', type: 'dhcp'
    bare.vm.provision 'ansible_local' do |ansible|
      ansible.playbook = 'bare/playbook.yml'
      ansible.extra_vars = ansible_extra_vars
      ansible.verbose = true
      ansible.skip_tags = 'letsencrypt'
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.env = {
        'TARGET' => 'rhel'
      }
      shell.inline = install_goss
      shell.inline = postgres_use_md5
    end
  end

  config.vm.define 'rhel9', autostart: false do |bare|
    bare.vm.box = 'generic/rocky9'
    bare.vm.network 'private_network', type: 'dhcp'
    #Not specifying this results in
    #this error to be displayed "`playbook` does not exist on the guest: /vagrant/bare/playbook.yml error"
    #The generic image might be a just a little bit broken, but rockylinux/9 is not ready yet
    bare.vm.synced_folder ".", "/vagrant"
    bare.vm.provision 'ansible_local' do |ansible|
      ansible.playbook = 'bare/playbook.yml'
      ansible.extra_vars = ansible_extra_vars
      ansible.verbose = true
      ansible.skip_tags = 'letsencrypt'
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.env = {
        'TARGET' => 'rhel'
      }
      shell.inline = install_goss
      shell.inline = postgres_use_md5
    end
  end
end
