module RadishFeed
  class Postgres < Ginseng::Postgres::Database
    include Package

    def self.dsn
      return Ginseng::Postgres::DSN.parse(Config.instance['/postgres/dsn'])
    end
  end
end
