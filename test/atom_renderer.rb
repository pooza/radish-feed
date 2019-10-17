module RadishFeed
  class ATOMRendererTest < Test::Unit::TestCase
    def test_params=
      atom = ATOMRenderer.new
      assert_equal(atom.params, {})

      atom.params = {tag: 'pooza', entries: 30}
      assert_equal(atom.params[:tag], 'pooza')
    end

    def test_create_link
      atom = ATOMRenderer.new
      assert_equal(
        atom.send(:create_link, 'https://precure.ml/users/skull_Servant/statuses/101023575287826044'),
        'https://precure.ml/@skull_Servant/101023575287826044',
      )
    end
  end
end
