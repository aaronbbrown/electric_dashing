require 'sequel'
require 'time'
require 'date'
require 'logger'
require_relative 'egauge'

def generation_since(start, register_name)
  query = <<-SQL
    select sum(watt_hours) as sum_wh
    from series s
    join registers r
      ON r.id = s.register_id
    where time >= ?
      and r.name = ?
  SQL
  result = DB[query, start, register_name].first
  result[:sum_wh].nil? ? 0 : result[:sum_wh].abs.round(1)
end

REGISTER = 'gen'
USAGE_REGISTER = 'use'
LOGGER = Logger.new($stderr)
LOGGER.level = ENV['DASHBOARD_DEBUG'].nil? ? Logger::INFO : Logger::DEBUG

if ENV['EGAUGE_URL'].nil? || ENV['EGAUGE_URL'].empty?
  LOGGER.fatal 'Please set $EGAUGE_URL.  Example: EGAUGE_URL="http://solar.example.com"'
  abort
end

if ENV['DB_URL'].nil? || ENV['DB_URL'].empty?
  LOGGER.fatal('Please set $DB_URL.  Example: DB_URL=postgres://user:password@host:5432/database')
  abort
end

Egauge.configure do |config|
  config.url = ENV['EGAUGE_URL']
end

Sequel.extension :migration
DB = Sequel.connect(ENV['DB_URL'], logger: LOGGER, sql_log_level: :debug)

migration_path = File.expand_path('../../db/migrate', __FILE__)
Sequel::Migrator.run(DB, migration_path)
