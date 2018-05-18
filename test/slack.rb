require 'radish-feed/slack'

module RadishFeed
  class SlackTest < Test::Unit::TestCase
    def test_all
      Slack.all do |slack|
        assert_true(slack.is_a?(Slack))
      end
    end

    def test_say
      Slack.all do |slack|
        assert_true(slack.say({text: 'hoge'}).response.is_a?(Net::HTTPOK))
      end
    end
  end
end

