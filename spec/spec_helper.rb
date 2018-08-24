require 'docker-api'
require 'pg'
require 'serverspec'

module Helpers
  def can_create_postgres_table
    pg = PG::Connection.new(
      host: '127.0.0.1',
      user: 'mastodon',
      dbname: 'mastodon_development',
      password: 'CHANGEME'
    )

    res = pg.query('CREATE TABLE test (v varchar(20)); DROP TABLE test;')
    res.result_status == PG::PGRES_COMMAND_OK
  ensure
    pg.close
  end
end

RSpec.configure do |c|
  c.include Helpers
  c.extend Helpers
end
