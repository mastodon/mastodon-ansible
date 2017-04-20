require 'spec_helper'

set :os, family: :ubuntu
set :backend, :exec

describe 'Ansible Debian target' do
  describe user('mastodon') do
    it { should exist }
  end

  describe command('ruby -v') do
    its(:stdout) { should match(/2\.4\.1p111/) }
  end
end
