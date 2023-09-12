ansible_version = File.read('requirements.txt').split.find { |item| item.start_with? 'ansible==' }.split('==')[1]
goss_version = '0.3.21'
pebble_version = '2.3.1'
install_goss = <<~SHELL
  echo "Running Goss tests:"
  echo "The target is \$TARGET" && \
  curl -Lo /tmp/goss https://github.com/aelsabbahy/goss/releases/download/v#{goss_version}/goss-linux-amd64 && \
  echo "9a9200779603acf0353d2c0e85ae46e083596c10838eaf4ee050c924678e4fe3  /tmp/goss" | sha256sum -c --strict - && \
  sudo install -m0755 -o root -g root /tmp/goss /usr/bin/goss && \
  rm /tmp/goss
  cd /vagrant
  sudo -E goss --vars vars.yaml validate
SHELL

#Fix for https://github.com/mastodon/mastodon-ansible/pull/33#issuecomment-1126071199
postgres_use_md5 = <<-'SHELL'
echo "Running PostgreSQL commands required for testing"
sudo sed -i 's/host\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\s127.0.0.1\/32\s\s\s\s\s\s\s\s\s\s\s\sident/host    all             all             127.0.0.1\/32                 md5/g' /var/lib/pgsql/data/pg_hba.conf
sudo sed -i 's/host\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\sall\s\s\s\s\s\s\s\s\s\s\s\s\s::1\/128\s\s\s\s\s\s\s\s\s\s\s\s\s\s\s\s\sident/host    all             all             ::1\/128                 md5/g' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
SHELL

#Need to run this under root for it to stick and not throw permission errors
#Enabling PEBBLE_VA_ALWAYS_VALID=1 as final challenge response from Pebble returns an empty body 
#and always fails the HTTP-01 ACME challenge. Possible upstream bug?
#Until its fixed we don't need Pebble ACME Response Server for the time being
localhost_domain = <<~SHELL
  echo "Set localhost to answer to mastodon.local"
  sudo su
  echo "127.0.0.1       mastodon.local" >> /etc/hosts
  echo "Run preventive cleanup tasks for Pebble ACME Server"
  rm -rf /etc/letsencrypt/accounts/localhost:14000
  echo "Download Pebble ACME Server tarball containing tests"
  curl -Lo /tmp/pebble-v#{pebble_version}.tar.gz https://github.com/letsencrypt/pebble/archive/refs/tags/v#{pebble_version}.tar.gz
  tar -xvzf /tmp/pebble-v#{pebble_version}.tar.gz -C /tmp/
  echo "Install and start Pebble ACME Server binary for testing"
  curl -Lo /tmp/pebble-#{pebble_version}/pebble https://github.com/letsencrypt/pebble/releases/download/v#{pebble_version}/pebble_linux-amd64
  chmod +x /tmp/pebble-#{pebble_version}/pebble
  echo "PEBBLE_VA_ALWAYS_VALID=1 /tmp/pebble-#{pebble_version}/pebble -config ./test/config/pebble-config.json" > /tmp/pebble-#{pebble_version}/pebble.sh && chmod +x /tmp/pebble-#{pebble_version}/pebble.sh
  cd /tmp/pebble-#{pebble_version} && nohup ./pebble.sh  &> /tmp/pebble.log&
  #sleep 2 && cat /tmp/pebble.log #Debug Option, use for when debugging ACME auth issues
SHELL

ansible_extra_vars = {
  mastodon_db_password: 'CHANGEME',
  mastodon_host: 'mastodon.local',
  redis_pass: 'CHANGEME',
  local_domain: 'mastodon.local',
  certbot_extra_param: '--server https://localhost:14000/dir --no-verify-ssl',
  use_legacy_certbot: 'false',
  letsencrypt_email: 'webmaster@mastodon.local'
}

Vagrant.require_version ">= 2.3.5"
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
      #MacOS Ventura workaround
      #bare.vm.network :private_network, type: 'dhcp', name: "HostOnly", virtualbox__intnet: true
      bare.vm.network 'private_network', type: 'dhcp'

      #Needs to be ran before running the playbook or Ansible checks will fail
      #as we are checking against non-valid FQDN
      bare.vm.provision 'shell' do |shell|
        shell.privileged = true
        shell.inline = localhost_domain
      end

      bare.vm.provision 'ansible' do |ansible|
        ansible.playbook = 'bare/playbook.yml'
        ansible.extra_vars = ansible_extra_vars
        ansible.version = ansible_version
        ansible.verbose = true
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
    #For VMWare Provider, you can use generic/rocky8
    #bare.vm.box = 'generic/rocky8'
    bare.vm.box = 'geerlingguy/rockylinux8'
      #MacOS Ventura workaround
      #bare.vm.network :private_network, type: 'dhcp', name: "HostOnly", virtualbox__intnet: true
      bare.vm.network 'private_network', type: 'dhcp'

    #Needs to be ran before running the playbook or Ansible checks will fail
    #as we are checking against non-valid FQDN
    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.inline = localhost_domain
    end

    bare.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'bare/playbook.yml'
      ansible.version = ansible_version
      ansible.extra_vars = ansible_extra_vars
      ansible.verbose = true
    end

    #We can't have two shell.inline for some reason or the first one won't run
    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.inline = postgres_use_md5
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.env = {
        'TARGET' => 'rhel'
      }
      shell.inline = install_goss
    end
  end

  config.vm.define 'rhel9', autostart: false do |bare|
    bare.vm.box = 'generic/rocky9'
    bare.vm.network 'private_network', type: 'dhcp'
    #Not specifying this results in
    #this error to be displayed "`playbook` does not exist on the guest: /vagrant/bare/playbook.yml error"
    #The generic image might be a just a little bit broken, but rockylinux/9 is not ready yet
    bare.vm.synced_folder ".", "/vagrant"

    #Needs to be ran before running the playbook or Ansible checks will fail
    #as we are checking against non-valid FQDN
    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.inline = localhost_domain
    end

    bare.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'bare/playbook.yml'
      ansible.version = ansible_version
      ansible.extra_vars = ansible_extra_vars
      ansible.verbose = true
    end

    #We can't have two shell.inline for some reason or the first one won't run
    bare.vm.provision 'shell' do |shell|
      shell.privileged = true
      shell.inline = postgres_use_md5
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
