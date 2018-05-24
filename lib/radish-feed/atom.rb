require 'rss'
require 'sanitize'
require 'radish-feed/renderer'
require 'radish-feed/config'
require 'radish-feed/postgres'
require 'radish-feed/tweet_string'

module RadishFeed
  class Atom < Renderer
    attr_accessor :query
    attr_reader :params
    attr_reader :tweetable
    attr_reader :title_length
    attr_reader :actor_type
    attr_accessor :hashtag

    def initialize
      super
      @params = []
      @tweetable = false
    end

    def type
      return 'application/atom+xml; charset=UTF-8'
    end

    def params=(values)
      @params = values
      entries = @params[:entries].to_i
      entries = @config['local']['entries']['default'].to_i if entries.zero?
      entries = [entries, @config['local']['entries']['max'].to_i].min
      @params[:entries] = entries
    end

    def tweetable=(flag)
      return if flag.nil?
      @tweetable = !flag.to_i.zero?
    rescue
      @tweetable = !!flag
    end

    def title_length=(length)
      @title_length = length.to_i unless length.nil?
    end

    def actor_type=(type)
      @actor_type = (type || 'Person')
    end

    def to_s
      return feed.to_s
    end

    private

    def db
      return Postgres.instance
    end

    def feed
      raise 'クエリー名が未定義です。' unless @query
      return RSS::Maker.make('atom') do |maker|
        update_channel(maker.channel)
        maker.items.do_sort = true
        values = @params.clone
        values[:actor_type] = @actor_type
        values[:hashtag] = @hashtag
        db.execute(@query, values).each do |row|
          maker.items.new_item do |item|
            item.link = row['uri']
            item.title = TweetString.new(row['text'])
            item.title.tweetablize!(@title_length) if @tweetable
            item.date = Time.parse(row['created_at']) + tz_offset
          end
        end
      end
    end

    def update_channel(channel)
      channel.id = @config['local']['root_url']
      channel.title = site['site_title']
      if (@query == 'account_timeline') && @params.present?
        channel.id += "@#{@params.first}"
        channel.title = "@#{@params.first} #{channel.title}"
      end
      channel.link = channel.id
      channel.description = Sanitize.clean(site['site_description'])
      channel.author = site['site_contact_username']
      channel.date = Time.now
    end

    def tz_offset
      return (@config['local']['tz_offset'] || 0) * 3600
    end

    def site
      unless @site
        @site = {}
        db.execute('site').each do |row|
          @site[row['var']] = YAML.safe_load(row['value'])
        end
      end
      return @site
    end
  end
end
