require 'uri'
require 'zlib'
require 'radish-feed/config'

module RadishFeed
  class TweetString < String
    def initialize (value)
      @config = Config.instance['twitter']
      super(value)
    end

    def length
      return self.each_char.map{|c| c.bytesize == 1 ? 0.5 : 1}.reduce(:+)
    end

    def index (search)
      return self[0..(super(search) - 1)].length
    end

    def tweetablize! (length = nil)
      length ||= (@config['length']['tweet'] - @config['length']['uri'] - 1.0)
      links = {}
      text = self.clone
      URI.extract(text, ['http', 'https']).each do |link|
        pos = text.index(link)
        if (length - @config['length']['uri'] - 0.5) < pos
          text.ellipsize!(pos - 0.5)
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
      self.replace(text)
      return self
    end

    def ellipsize! (length)
      i = 0
      ellipsized = ''
      self.each_char.map do |c|
        if c.bytesize == 1
          i += 0.5
        else
          i += 1
        end
        if length < i
          self.replace(ellipsized + '…')
          break
        end
        ellipsized += c
      end
      return self
    end

    private
    def create_tag (key)
      return sprintf('{crc:%0' + (@config['length']['uri'] - 9).to_s + 'd}', key)
    end
  end
end
