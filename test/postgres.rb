module RadishFeed
  class PostgresTest < Test::Unit::TestCase
    def test_dsn
      assert_kind_of(Ginseng::Postgres::DSN, Postgres.dsn)
    end
  end
end
