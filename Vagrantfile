# frozen_string_literal: true

goss_version = "0.3.16"

# vim: set syntax=ruby:
# rubocop:disable Metrics/BlockLength
# rubocop:disable Layout/HeredocIndentation
Vagrant.configure('2') do |config|
#RAM has to be bumped up due of precompile assets silently failing with just 1GB of RAM
#https://github.com/rails/webpacker/issues/955
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"

    # We need to disable nested virtualization since GitHub Actions doesn't support it
    # https://github.com/actions/virtual-environments/issues/183#issuecomment-610723516
    vb.customize ["modifyvm", :id, "--hwvirtex", "off"] if ENV['CI'] == "true"
    vb.customize ["modifyvm", :id, "--vtxvpid", "off"] if ENV['CI'] == "true"
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
        disable_letsencrypt: 'true'
      }
      ansible.verbose = true
      ansible.skip_tags = 'letsencrypt'
    end

    %w[goss.yaml vars.yaml].each do |file|
      bare.vm.provision 'file',
                        source: file,
                        destination: file
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = false
      shell.inline = <<SHELL
curl -Lo /tmp/goss https://github.com/aelsabbahy/goss/releases/download/v#{goss_version}/goss-linux-amd64 && \
echo "827e354b48f93bce933f5efcd1f00dc82569c42a179cf2d384b040d8a80bfbfb  /tmp/goss" | sha256sum -c --strict - && \
sudo install -m0755 -o root -g root /tmp/goss /usr/bin/goss && \
rm /tmp/goss
cd /vagrant
sudo goss --vars vars.yaml validate
SHELL
    end
  end
end
# rubocop:enable Layout/HeredocIndentation
# rubocop:enable Metrics/BlockLength



