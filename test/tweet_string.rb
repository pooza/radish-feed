require 'radish-feed/tweet_string'

module RadishFeed
  class TweetStringTest < Test::Unit::TestCase
    def test_length
      str = TweetString.new('ああああえええeee')
      assert_equal(str.length, 8.5)

      str = TweetString.new('ああああ')
      assert_equal(str.length, 4)
    end

    def test_index
      str = TweetString.new('ああああえええeee')
      assert_equal(str.index('eee'), 7)

      str = TweetString.new('ああああefef')
      assert_equal(str.index('f'), 4.5)

      str = TweetString.new('ああああefefx')
      assert_equal(str.index('fx'), 5.5)
    end

    def test_ellipsize!
      str = TweetString.new('ああああえええeee')
      assert_equal(str.ellipsize!(100), 'ああああえええeee')

      str = TweetString.new('ああああえええeee')
      assert_equal(str.ellipsize!(3), 'あああ…')

      str = TweetString.new('ああああええaabbcc')
      assert_equal(str.ellipsize!(8), 'ああああええaabb…')

      str = TweetString.new('ああaああええaabbcc')
      assert_equal(str.ellipsize!(3), 'ああa…')
    end

    def test_tweetablize!
      str = TweetString.new('https://google.com')
      assert_equal(str.tweetablize!, 'https://google.com')

      str = TweetString.new('ああああああああ https://google.com')
      assert_equal(str.tweetablize!(8), 'ああああああああ…')

      str = TweetString.new('aaaaaaaaaa https://google.com')
      assert_equal(str.tweetablize!(6), 'aaaaaaaaaa…')

      str = TweetString.new('112233445566778899001122334455667788990011223344556677889900112233445566778899001122334455667788990011223344556677889900112233445566778899001122334455667788990011223344556677889900112233445566778899001122334455667788990011223344556677889900 https://google.com')
      assert_equal(str.tweetablize!, '11223344556677889900112233445566778899001122334455667788990011223344556677889900112233445566778899001122334455667788990011223344556677889900112233445566778899001122334455667788990011223344556677889900112233445566778899001122334455…')
    end
  end
end
