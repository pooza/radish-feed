require 'pg'
require 'erb'
require 'singleton'
require 'radish-feed/config'

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
    end

    def escape_string(value)
      return @db.escape_string(value)
    end

    def create_sql(name, params = {})
      params.map{ |k, v| params[k] = @db.escape_string(v)}
      return ERB.new(@config['query'][name]).result
    end

    def execute(name, params = {})
      return @db.exec(creeate_sql(name, params)).to_a
    end
  end
end
