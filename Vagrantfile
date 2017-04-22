# vim: set syntax=ruby:
# rubocop:disable Metrics/BlockLength
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/xenial64'
  config.vm.network 'private_network', type: 'dhcp'

  config.vm.provision 'file',
                      source: 'templates/resolv.conf.tpl',
                      destination: '/tmp/resolv.conf'

  # Just install Python for now
  config.vm.provision 'shell' do |shell|
    shell.privileged = true
    shell.inline = <<EOF
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends python ruby-dev ruby-bundler libpq-dev
  sudo cp /tmp/resolv.conf /etc/resolv.conf && rm /tmp/resolv.conf
EOF
  end

  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = 'playbook.yml'
    ansible.extra_vars = {
      mastodon_db_password: 'CHANGEME'
    }
    ansible.verbose = true
  end

  %w[Gemfile Gemfile.lock spec .rspec].each do |file|
    config.vm.provision 'file',
                        source: file,
                        destination: file
  end

  config.vm.provision 'shell' do |shell|
    shell.privileged = false
    shell.inline = <<EOF
    bundle install --path vendor/bundle
    bundle exec rubocop
    bundle exec rspec
EOF
  end
end
# rubocop:enable Metrics/BlockLength
