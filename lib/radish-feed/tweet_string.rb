require 'uri'
require 'zlib'
require 'radish-feed/config'

module RadishFeed
  class TweetString < String
    def initialize (value)
      @config = Config.new['twitter']
      super(value)
    end

    def tweetable_text (length = nil)
      length ||= (@config['length']['tweet'] - @config['length']['uri'] - 2)
      links = {}
      text = self.clone
      URI.extract(text, ['http', 'https']).each do |link|
        pos = text.index(link)
        if (length - @config['length']['uri'] - 1) < pos
          text.ellipsize!(pos - 1)
          break
        else
          key = Zlib.adler32(text)
          links[key] = link
          text.sub!(link, create_tag(key))
        end
      end
      text.ellipsize!(length)
      links.each do |key, link|
        text.sub!(create_tag(key), link)
      end
      return text
    end

    def ellipsize! (length)
      if length < self.length
        self.replace(TweetString.new(self[0..(length - 1)] + '…'))
      end
      return self
    end

    private
    def create_tag (key)
      return sprintf('{crc:%0' + (@config['length']['uri'] - 9).to_s + 'd}', key)
    end
  end
end
