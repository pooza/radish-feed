require 'uri'
require 'zlib'
require 'radish-feed/config'

module RadishFeed
  class TweetString < String
    def initialize(value)
      @config = Config.instance['twitter']
      super(value)
    end

    def length
      return each_char.map do |c|
        c.bytesize == 1 ? 0.5 : 1.0
      end.reduce(:+)
    end

    def index(search)
      return self[0..(super(search) - 1)].length
    end

    def tweetablize!(length = nil)
      length ||= (@config['length']['tweet'] - @config['length']['uri'] - 1.0)
      links = {}
      text = clone
      URI.extract(text, ['http', 'https']).each do |link|
        pos = text.index(link)
        if (length - @config['length']['uri'] - 0.5) < pos
          text.ellipsize!(pos - 0.5)
          break
        end
        key = Zlib.adler32(link)
        links[key] = link
        text.sub!(link, create_tag(key))
      end
      text.ellipsize!(length)
      links.each do |key, link|
        text.sub!(create_tag(key), link)
      end
      replace(text)
      return self
    end

    def ellipsize!(length)
      i = 0
      str = ''
      each_char do |c|
        i += (c.bytesize == 1 ? 0.5 : 1.0)
        if length < i
          replace(str + '…')
          break
        end
        str += c
      end
      return self
    end

    private

    def create_tag(key)
      return '{crc:%0' + (@config['length']['uri'] - 9).to_s + 'd}' % key
    end
  end
end
