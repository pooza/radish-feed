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
      header 'User-Agent', Package.user_agent
      get '/about'
      assert(last_response.ok?)
    end

    def test_not_found
      header 'User-Agent', Package.user_agent
      get '/not_found'
      assert_false(last_response.ok?)
      assert_equal(last_response.status, 404)
    end

    def test_local_feed
      header 'User-Agent', Package.user_agent
      get '/feed/v1.1/local'
      assert(last_response.ok?)
      assert_equal(last_response.headers['Content-Type'], 'application/atom+xml; charset=UTF-8')
    end

    def test_account_feed
      Postgres.instance.execute('accounts', {limit: @config['/test/server/accounts/limit']}).each do |row|
        header 'User-Agent', Package.user_agent
        get "/feed/v1.1/account/#{row['username']}"
        assert(last_response.ok?)
        assert_equal(last_response.headers['Content-Type'], 'application/atom+xml; charset=UTF-8')
      end
    end
  end
end
