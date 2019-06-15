require 'rack/test'

module RadishFeed
  class ServerTest < Test::Unit::TestCase
    include ::Rack::Test::Methods

    def setup
      @config = Config.instance
    end

    def app
      return Server
    end

    def test_about
      return if ENV['CI'].present?
      get '/about'
      assert(last_response.ok?)
    end

    def test_not_found
      get '/not_found'
      assert_false(last_response.ok?)
      assert_equal(last_response.status, 404)
    end

    def test_local_feed
      return if ENV['CI'].present?
      get '/feed/v1.1/local'
      assert(last_response.ok?)
      assert_equal(last_response.headers['Content-Type'], 'application/atom+xml; charset=UTF-8')
    end

    def test_account_feed
      return if ENV['CI'].present?
      Postgres.instance.execute('accounts', {limit: @config['/test/server/accounts/limit']}).each do |row|
        get "/feed/v1.1/account/#{row['username']}"
        assert(last_response.ok?)
        assert_equal(last_response.headers['Content-Type'], 'application/atom+xml; charset=UTF-8')
      end
    end

    def test_404_account_feed
      return if ENV['CI'].present?
      get '/feed/v1.1/account/notfound_user_xxxx'
      assert_false(last_response.ok?)
      assert_equal(last_response.status, 404)
    end
  end
end
