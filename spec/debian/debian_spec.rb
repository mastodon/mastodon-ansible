require 'spec_helper'

set :os, family: :ubuntu
set :backend, :exec

# rubocop:disable Metrics/BlockLength
describe 'Ansible Debian target' do
  context 'web role' do
    describe user('mastodon') do
      it { should exist }
      it { should have_home_directory '/home/mastodon' }
      it { should have_login_shell '/bin/bash' }
    end

    describe file('/home/mastodon/.bashrc') do
      it { should exist }
      its(:content) { should match(/rbenv init -/) }
      its(:content) { should match(/PATH=/) }
      it { is_expected.to be_owned_by('mastodon') }
    end

    describe command('ruby -v') do
      its(:stdout) { should match(/2\.6\.6/) }
    end

    describe file('/usr/bin/nodejs') do
      it { should be_symlink }
    end

    %w[
      autoconf
      bison
      build-essential
      curl
      ffmpeg
      file
      g++
      gcc
      git
      imagemagick
      libffi-dev
      libgdbm-dev
      libgdbm5
      libicu-dev
      libidn11-dev
      libncurses5-dev
      libpq-dev
      libprotobuf-dev
      libreadline-dev
      libssl-dev
      libxml2-dev
      libxslt1-dev
      libyaml-dev
      nginx
      nodejs
      pkg-config
      protobuf-compiler
      sudo
      yarn
      zlib1g-dev
    ].each do |p|
      describe package(p) do
        it { should be_installed }
      end
    end

    describe file('/home/mastodon/.rbenv/plugins/ruby-build/bin/ruby-build') do
      it { should exist }
      it { should be_executable }
      it { is_expected.to be_owned_by('mastodon') }
    end

    describe command('ruby-build --version') do
      its(:stdout) { should match(/ruby-build 20200401/) }
    end

    describe file('/home/mastodon/live') do
      it { should exist }
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by('mastodon') }
    end

    describe file('/etc/systemd/system/mastodon-web.service') do
      it { should exist }
    end

    describe file('/etc/systemd/system/mastodon-streaming.service') do
      it { should exist }
    end

    describe file('/etc/systemd/system/mastodon-sidekiq.service') do
      it { should exist }
    end

    describe cron do
      it {
        should have_entry('15 1 * * * /bin/bash -c ' \
          '\'export PATH="$HOME/.rbenv/bin:$PATH"; ' \
          'eval "$(rbenv init -)"; cd /home/mastodon/live && ' \
          'RAILS_ENV=production ./bin/tootctl media remove\'')
          .with_user('mastodon')
      }
    end

    describe file('/etc/nginx/sites-available/mastodon.conf') do
      it { should exist }
    end

    describe file('/etc/nginx/sites-enabled/mastodon.conf') do
      it { should be_symlink }
    end

    # We can't install the firewall rules on circle ci due
    # to permissions inside of the docker container, we will
    # have to skip the tests for it.
    if ENV['CI'].nil?
      describe file('/home/vagrant/ufw_result.txt') do
        its(:content) { should match(/Status: active/) }

        expected_rules = [
          %r{22\/tcp \s* ALLOW \s* Anywhere},
          %r{80\/tcp \s* ALLOW \s* Anywhere},
          %r{443\/tcp \s* ALLOW \s* Anywhere},
          %r{22\/tcp \(v6\) \s* ALLOW \s* Anywhere \(v6\)},
          %r{80\/tcp \(v6\) \s* ALLOW \s* Anywhere \(v6\)},
          %r{443\/tcp \(v6\) \s* ALLOW  \s* Anywhere \(v6\)}
        ]

        expected_rules.each do |r|
          its(:content) { should match(r) }
        end
      end
    end
  end

  context 'postgres role' do
    describe port(5432) do
      it { should be_listening }
    end

    describe 'the mastodon user' do
      it 'should be able to create a table in "mastodon_development"' do
        expect(can_create_postgres_table).to be_truthy
      end
    end
  end

  context 'redis role' do
    %w[redis-server redis-tools].each do |p|
      describe package(p) do
        it { should be_installed }
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
