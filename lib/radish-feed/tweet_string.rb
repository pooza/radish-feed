require 'uri'
require 'radish-feed/config'

module RadishFeed
  class TweetString < String
    def initialize(value)
      @config = Config.instance['twitter']
      super(value)
    end

    def length
      return each_char.map{ |c| c.bytesize == 1 ? 0.5 : 1.0}.reduce(:+)
    end

    def index(search)
      return self[0..(super(search) - 1)].length
    rescue
      return nil
    end

    def tweetablize!(length = nil)
      links = []
      text = clone
      URI.extract(text, ['http', 'https']).each do |link|
        text.sub!(link, "\0")
        links.push(link)
      end
      text.ellipsize!(length || @config['length']['tweet'])
      links.each do |link|
        break unless text.index("\0")
        text.sub!("\0", link)
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
  end
end
