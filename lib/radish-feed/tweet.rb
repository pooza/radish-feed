require 'uri'
require 'zlib'

module RadishFeed
  class Tweet < String
    FULL_LENGTH = 140
    URI_LENGTH = 24

    def tweetable_text
      links = {}
      text = String.new(self)
      URI.extract(text, ['http', 'https']).each do |link|
        pos = text.index(link)
        if (max_length - URI_LENGTH) < (pos + 1)
          text = text[0..(pos - 1)].rstrip + '…'
          break
        else
          key = Zlib.adler32(text)
          links[key] = link
          text.sub!(link, create_tag(key))
        end
      end
      if max_length < text.length
        text = text[0..max_length].rstrip + '…'
      end
      links.each do |key, link|
        text.sub!(create_tag(key), link)
      end
      return text
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
