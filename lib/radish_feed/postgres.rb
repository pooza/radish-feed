require 'pg'
require 'erb'
require 'singleton'

module RadishFeed
  class Postgres
    include Singleton

    def initialize
      @config = Config.instance
      @db = PG.connect({
        host: @config['db']['host'],
        user: @config['db']['user'],
        password: @config['db']['password'],
        dbname: @config['db']['dbname'],
        port: @config['db']['port'],
      })
    rescue => e
      raise DatabaseError, e.message
    end

    def escape_string(value)
      return @db.escape_string(value)
    end

    def create_sql(name, params = {})
      params.each do |k, v|
        params[k] = escape_string(v) if v.is_a?(String)
      end
      return ERB.new(@config['query'][name]).result(binding).gsub(/\s+/, ' ')
    end

    def execute(name, params = {})
      return @db.exec(create_sql(name, params)).to_a
    rescue => e
      raise DatabaseError, e.message
    end
  end
end
