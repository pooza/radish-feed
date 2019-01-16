module RadishFeed
  class Postgres < Ginseng::Postgres::Database
    include Singleton
    include Package

    def default_dbname
      return 'mastodon'
    end

    def self.dsn
      config = Config.instance
      return Ginseng::Postgres::DSN.parse(config['/postgres/dsn'])
    rescue
      path = File.join(Environment.dir, 'config/db.yaml')
      config.update(YAML.load_file(path).map{ |k, v| ["/db/#{k}", v]}.to_h) if File.exist?(path)
      config['/postgres/dsn'] = 'postgres://%{user}:%{password}@%{host}/%{dbname}' % {
        user: config['/db/user'],
        password: config['/db/password'],
        host: config['/db/host'],
        dbname: config['/db/dbname'],
      }
      return Ginseng::Postgres::DSN.parse(config['/postgres/dsn'])
    end
  end
end
