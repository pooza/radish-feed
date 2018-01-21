require 'uri'
require 'zlib'

module RadishFeed
  class TweetString < String
    FULL_LENGTH = 140
    URI_LENGTH = 24

    def tweetable_text
      links = {}
      text = self.clone
      URI.extract(text, ['http', 'https']).each do |link|
        pos = text.index(link)
        if (max_length - URI_LENGTH - 1) < pos
          text.ellipsize!(pos - 1)
          break
        else
          key = Zlib.adler32(text)
          links[key] = link
          text.sub!(link, create_tag(key))
        end
      end
      text.ellipsize!(max_length)
      links.each do |key, link|
        text.sub!(create_tag(key), link)
      end
      return text
    end

    def ellipsize! (length)
      if length < self.length
        self.replace(self.new(self[0..length] + '…'))
      end
      return self
    end

    private
    def max_length
      return FULL_LENGTH - URI_LENGTH - 2
    end

    def create_tag (key)
      return sprintf('{crc:%0' + (URI_LENGTH - 9).to_s + 'd}', key)
    end
  end
end
