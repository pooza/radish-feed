require 'radish-feed/atom'
require 'radish-feed/config'

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
      assert_equal(atom.params, {})

      atom.params = {entries: 20}
      assert_equal(atom.params[:entries], 20)

      atom.params = {account: 'pooza', entries: 30}
      assert_equal(atom.params[:account], 'pooza')
      assert_equal(atom.params[:entries], 30)

      atom.params = {account: 'admin', entries: 1000}
      assert_equal(atom.params[:account], 'admin')
      assert_equal(atom.params[:entries], Config.instance['local']['entries']['max'])
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

    def test_actor_type=
      atom = Atom.new
      assert_nil(atom.actor_type)

      atom.actor_type = 'Service'
      assert_equal(atom.actor_type, 'Service')

      atom.actor_type = nil
      assert_equal(atom.actor_type, 'Person')
    end

    def test_ignore_cw=
      atom = Atom.new
      assert_equal(atom.ignore_cw, false)

      atom.ignore_cw = true
      assert_equal(atom.ignore_cw, true)

      atom.ignore_cw = nil
      assert_equal(atom.ignore_cw, true)

      atom.ignore_cw = 0
      assert_equal(atom.ignore_cw, false)

      atom.ignore_cw = 1
      assert_equal(atom.ignore_cw, true)

      atom.ignore_cw = '0'
      assert_equal(atom.ignore_cw, false)
    end

    def test_attachments=
      atom = Atom.new
      assert_equal(atom.attachments, false)

      atom.attachments = true
      assert_equal(atom.attachments, true)

      atom.attachments = nil
      assert_equal(atom.attachments, true)

      atom.attachments = 0
      assert_equal(atom.attachments, false)

      atom.attachments = 1
      assert_equal(atom.attachments, true)

      atom.attachments = '0'
      assert_equal(atom.attachments, false)
    end
  end
end
