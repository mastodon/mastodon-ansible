# vim: set syntax=ruby:
# rubocop:disable Metrics/BlockLength
Vagrant.configure('2') do |config|
  config.vm.define 'bare' do |bare|
    bare.vm.box = 'ubuntu/xenial64'
    bare.vm.network 'private_network', type: 'dhcp'
    bare.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'bare/playbook.yml'
      ansible.extra_vars = {
        mastodon_db_password: 'CHANGEME'
      }
      ansible.verbose = true
    end

    %w[Gemfile Gemfile.lock spec .rspec].each do |file|
      bare.vm.provision 'file',
                        source: file,
                        destination: file
    end

    bare.vm.provision 'shell' do |shell|
      shell.privileged = false
      shell.inline = <<EOF
      bundle install --path vendor/bundle
      bundle exec rubocop
      bundle exec rspec
EOF
    end
  end

  config.vm.define 'docker', primary: true do |docker|
    docker.vm.box = 'ubuntu/xenial64'
    docker.vm.network 'private_network', type: 'dhcp'
    docker.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'docker/playbook.yml'
      ansible.verbose = true
    end
  end
end
# rubocop:enable Metrics/BlockLength
