module RadishFeed
  class Tweet < String
    def tweetable_text
      return String.new(self)
    end
  end
end
