require 'spec_helper'

set :os, family: :ubuntu
set :backend, :exec

def create_postgres_table
  pg = PG::Connection.new(
    host: '127.0.0.1',
    user: 'mastodon',
    dbname: 'mastodon_development',
    password: 'CHANGEME'
  )

  res = pg.query('CREATE TABLE test (v varchar(20));')
  res.result_status == PG::PGRES_COMMAND_OK
ensure
  pg.close
end

describe 'Ansible Debian target' do
  describe user('mastodon') do
    it { should exist }
  end

  describe command('ruby -v') do
    its(:stdout) { should match(/2\.4\.1p111/) }
  end

  context 'With PostgreSQL' do
    describe 'the mastodon user' do
      it 'should be able to create a table in "mastodon_development"' do
        expect(create_postgres_table).to be_truthy
      end
    end
  end
end
