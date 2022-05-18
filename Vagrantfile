goss_version = '0.3.16'
install_goss = <<~SHELL
  curl -Lo /tmp/goss https://github.com/aelsabbahy/goss/releases/download/v#{goss_version}/goss-linux-amd64 && \
  echo "827e354b48f93bce933f5efcd1f00dc82569c42a179cf2d384b040d8a80bfbfb  /tmp/goss" | sha256sum -c --strict - && \
  sudo install -m0755 -o root -g root /tmp/goss /usr/bin/goss && \
  rm /tmp/goss
  cd /vagrant
  sudo -E goss --vars vars.yaml validate
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

      bare.vm.provision 'shell' do |shell|
        shell.privileged = true
        shell.inline = <<~SHELL
          install -m0777 -d -o vagrant -o vagrant /var/tmp/ansible
        SHELL
      end

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

  config.vm.define 'rhel', autostart: false do |bare|
    bare.vm.box = 'bento/rockylinux-8.5'
    bare.vm.network 'private_network', type: 'dhcp'

    bare.vm.provision 'shell' do |shell|
      shell.privileged = true

      # We need to install Ansible manually here because the system-provided Ansible is broken
      shell.inline = <<~SHELL
        install -m0777 -d -o vagrant -o vagrant /var/tmp/ansible && \
        dnf install -y python3 python3-pip python3-cryptography python3-devel python3-setuptools && \
        alternatives --set python /usr/bin/python3 && \
        alternatives --set python3 /usr/bin/python3.6 && \
        pip3 install ansible
      SHELL
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.inline = <<~SHELL
        cd /vagrant && \
        /usr/local/bin/ansible-galaxy install -r meta/requirements.yml
      SHELL
    end

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

      # Fix for https://github.com/mastodon/mastodon-ansible/pull/33#issuecomment-1126071199
      shell.inline = <<~POSTGRES
        sed -i -e 's/\\(^host\\s*all.*\\)ident/\\1md5/g' /var/lib/pgsql/data/pg_hba.conf && \
        systemctl restart postgresql
      POSTGRES
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.env = {
        'TARGET' => 'rhel'
      }

      shell.inline = install_goss
    end
  end
end
