require 'radish-feed/postgres'

module RadishFeed
  class PostgresTest < Test::Unit::TestCase
    def test_escape_string
      @db = Postgres.instance
      assert_equal(@db.escape_string('あえ'), 'あえ')
      assert_equal(@db.escape_string(%(あえ")), %(あえ\"))
      assert_equal(@db.escape_string(%(あえ')), %(あえ''))
    end

    def test_create_sql
      @db = Postgres.instance
      assert_equal(@db.create_sql('registered', {account: 'pooza'}), %!SELECT id FROM accounts WHERE (domain IS NULL) AND (locked='f') AND (username='pooza');!)
      assert_equal(@db.create_sql('account_timeline', {account: 'pooza', entries: 300}), %!SELECT toots.uri, toots.created_at, toots.text, toots.spoiler_text FROM statuses AS toots INNER JOIN accounts ON toots.account_id=accounts.id WHERE (accounts.domain IS NULL) AND (accounts.locked='f') AND (accounts.username='pooza') AND (toots.visibility=0) AND (toots.text<>'') AND (toots.uri IS NOT NULL) AND (toots.text \!~ '@[_a-zA-Z0-9]+(@[-.a-z0-9]+)?[ \\n]')   ORDER BY toots.created_at DESC LIMIT 300 OFFSET 0;!)
      assert_equal(@db.create_sql('account_timeline', {account: 'pooza', entries: 300, actor_type: 'Service'}), %!SELECT toots.uri, toots.created_at, toots.text, toots.spoiler_text FROM statuses AS toots INNER JOIN accounts ON toots.account_id=accounts.id WHERE (accounts.domain IS NULL) AND (accounts.locked='f') AND (accounts.username='pooza') AND (toots.visibility=0) AND (toots.text<>'') AND (toots.uri IS NOT NULL) AND (toots.text \!~ '@[_a-zA-Z0-9]+(@[-.a-z0-9]+)?[ \\n]')  AND (accounts.actor_type='Service')   ORDER BY toots.created_at DESC LIMIT 300 OFFSET 0;!)
      assert_equal(@db.create_sql('account_timeline', {account: 'pooza', entries: 300, actor_type: 'Person'}), %!SELECT toots.uri, toots.created_at, toots.text, toots.spoiler_text FROM statuses AS toots INNER JOIN accounts ON toots.account_id=accounts.id WHERE (accounts.domain IS NULL) AND (accounts.locked='f') AND (accounts.username='pooza') AND (toots.visibility=0) AND (toots.text<>'') AND (toots.uri IS NOT NULL) AND (toots.text \!~ '@[_a-zA-Z0-9]+(@[-.a-z0-9]+)?[ \\n]')  AND ((accounts.actor_type='Person') OR (accounts.actor_type IS NULL))   ORDER BY toots.created_at DESC LIMIT 300 OFFSET 0;!)
      assert_equal(@db.create_sql('account_timeline', {account: 'pooza', entries: 300, hashtag: 'precure'}), %!SELECT toots.uri, toots.created_at, toots.text, toots.spoiler_text FROM statuses AS toots INNER JOIN accounts ON toots.account_id=accounts.id WHERE (accounts.domain IS NULL) AND (accounts.locked='f') AND (accounts.username='pooza') AND (toots.visibility=0) AND (toots.text<>'') AND (toots.uri IS NOT NULL) AND (toots.text \!~ '@[_a-zA-Z0-9]+(@[-.a-z0-9]+)?[ \\n]')   AND (toots.text ~ '#precure')  ORDER BY toots.created_at DESC LIMIT 300 OFFSET 0;!)
    end
  end
end
