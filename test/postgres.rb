require 'radish-feed/postgres'

module RadishFeed
  class PostgresTest < Test::Unit::TestCase
    def test_escape_string
      @db = Postgres.instance
      assert_equal(@db.escape_string('あえ'), 'あえ')
    end
  end
end
