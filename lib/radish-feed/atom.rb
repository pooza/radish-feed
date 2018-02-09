require 'rss'
require 'radish-feed/renderer'
require 'radish-feed/config'
require 'radish-feed/postgres'
require 'radish-feed/tweet_string'

module RadishFeed
  class Atom < Renderer
    def initialize
      super
      @db = Postgres.new
      @config = Config.new
      @tweetable = false
    end

    def type
      return 'application/atom+xml; charset=UTF-8'
    end

    def tweetable= (flag)
      unless flag.nil?
        begin
          @tweetable = (flag.to_i != 0)
        rescue
          @tweetable = !!flag
        end
      end
    end

    def title_length= (length)
      @title_length = length.to_i unless length.nil?
    end

    def generate (type, params)
      return RSS::Maker.make('atom') do |maker|
        maker.channel.id = @config['local']['root_url']
        maker.channel.title = site['site_title']
        maker.channel.description = site['site_description']
        maker.channel.link = @config['local']['root_url']
        maker.channel.author = site['site_contact_username']
        maker.channel.date = Time.now
        maker.items.do_sort = true

        entries = params.pop
        entries = @config['local']['entries']['default'] if entries.zero?
        if @config['local']['entries']['max'] < entries
          entries = @config['local']['entries']['max']
        end
        params.push(entries)

        @db.execute(type, params).each do |row|
          maker.items.new_item do |item|
            item.link = row['uri']
            if @tweetable
              item.title = TweetString.new(row['text']).tweetable_text(@title_length)
            else
              item.title = row['text']
            end
            item.date = Time.parse(row['created_at']) + tz_offset
          end
        end
      end
    end

    private
    def tz_offset
      return (@config['local']['tz_offset'] || 0) * 3600
    end

    def site
      unless @site
        @site = {}
        @db.execute('site').each do |row|
          @site[row['var']] = YAML.load(row['value'])
        end
      end
      return @site
    end
  end
end
