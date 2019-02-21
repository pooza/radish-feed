module RadishFeed
  class PostgresTest < Test::Unit::TestCase
    def test_dsn
      assert(Postgres.dsn.is_a?(Ginseng::Postgres::DSN))
    end
  end
end
