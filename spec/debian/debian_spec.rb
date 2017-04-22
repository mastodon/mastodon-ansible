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

    describe file('/etc/profile.d/rbenv.sh') do
      it { should exist }
      its(:content) { should match(/rbenv init -/) }
      its(:content) { should match(/RBENV_ROOT/) }
      its(:content) { should match(/PATH=/) }
    end

    describe command('ruby -v') do
      its(:stdout) { should match(/2\.4\.1p111/) }
    end

    describe file('/usr/bin/node') do
      it { should be_symlink }
    end

    %w[
      apt-transport-https
      ca-certificates
      libssl-dev
      zlib1g-dev
      git-core
      build-essential
      libxml2-dev
      libxslt1-dev
      imagemagick
      nodejs
      yarn
      libreadline-dev
      ffmpeg
      curl
      sudo
    ].each do |p|
      describe package(p) do
        it { should be_installed }
      end
    end

    describe file('/usr/bin/ruby-build') do
      it { should exist }
      it { should be_executable }
    end

    describe command('ruby-build --version') do
      pending('https://github.com/rbenv/ruby-build/issues/1078') do
        its(:stdout) { should match(/ruby-build 20170405/) }
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
    describe port(6379) do
      it { should be_listening }
    end

    describe service('redis') do
      it { should be_running }
    end
  end
end
# rubocop:enable Metrics/BlockLength
