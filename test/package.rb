module RadishFeed
  class PackageTest < Test::Unit::TestCase
    def test_name
      assert_equal(Package.name, 'radish-feed')
    end
  end
end
