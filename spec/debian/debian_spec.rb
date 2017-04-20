require 'spec_helper'

set :os, family: :ubuntu
set :backend, :exec

describe 'Ansible Debian target' do
  describe user('mastodon') do
    it { should exist }
  end
end
