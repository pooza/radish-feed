require 'radish-feed/atom'

module RadishFeed
  class AtomTest < Test::Unit::TestCase
    def test_tweetable=
      atom = Atom.new
      assert_equal(atom.tweetable, false)

      atom.tweetable = true
      assert_equal(atom.tweetable, true)

      atom.tweetable = nil
      assert_equal(atom.tweetable, true)

      atom.tweetable = 0
      assert_equal(atom.tweetable, false)

      atom.tweetable = 1
      assert_equal(atom.tweetable, true)

      atom.tweetable = '0'
      assert_equal(atom.tweetable, false)
    end

    def test_params=
      atom = Atom.new
      assert_equal(atom.params, [])

      atom.params = [20]
      assert_equal(atom.params[0], 20)

      atom.params = ['pooza', '30']
      assert_equal(atom.params[0], 'pooza')
      assert_equal(atom.params[1], 30)

      atom.params = ['admin', '10000']
      assert_equal(atom.params[0], 'admin')
      assert_equal(atom.params[1], Config.instance['local']['entries']['max'])
    end

    def test_title_length=
      atom = Atom.new
      assert_nil(atom.title_length)

      atom.title_length = 100
      assert_equal(atom.title_length, 100)

      atom.title_length = '200'
      assert_equal(atom.title_length, 200)

      atom.title_length = nil
      assert_equal(atom.title_length, 200)
    end
  end
end
