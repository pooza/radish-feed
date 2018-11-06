require 'rss'
require 'socket'
require 'sanitize'
require 'addressable/uri'

module RadishFeed
  class AtomRenderer < Renderer
    attr_accessor :query
    attr_reader :params
    attr_reader :tweetable
    attr_reader :title_length
    attr_reader :actor_type
    attr_reader :attachments
    attr_reader :visibility
    attr_reader :ignore_cw
    attr_accessor :hashtag

    def initialize
      super
      @params = {}
      @tweetable = false
      @ignore_cw = false
      @attachments = false
      @visibility = 'public'
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

    def ignore_cw=(flag)
      return if flag.nil?
      @ignore_cw = !flag.to_i.zero?
    rescue
      @ignore_cw = !!flag
    end

    def attachments=(flag)
      return if flag.nil?
      @attachments = !flag.to_i.zero?
    rescue
      @attachments = !!flag
    end

    def title_length=(length)
      @title_length = length.to_i unless length.nil?
    end

    def actor_type=(type)
      @actor_type = type if type.present?
    end

    def visibility=(type)
      @visibility = (type || 'public')
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
        values[:attachments] = @attachments
        values[:visibility] = @visibility
        db.execute(@query, values).each do |row|
          maker.items.new_item do |item|
            item.link = row['uri']
            item.title = create_title(row)
            item.date = Time.parse("#{row['created_at']} UTC").getlocal(tz)
          end
        end
      end
    end

    def create_title(row)
      if row['spoiler_text'].present? && !ignore_cw
        title = TweetString.new('[閲覧注意]' + row['spoiler_text'])
      else
        title = TweetString.new(row['text'])
        title = TweetString.new('(空欄)') unless title.present?
      end
      title = "[@#{row['username']}] #{title}" if row['username']
      title.tweetablize!(@title_length) if @tweetable
      return title
    end

    def update_channel(channel)
      uri = Addressable::URI.parse(root_url)
      channel.title = Server.site['site_title']
      if (@query == 'account_timeline') && @params[:account]
        uri.path = "/@#{@params[:account]}"
        channel.title = "@#{@params[:account]} #{channel.title}"
      end
      channel.id = uri.to_s
      channel.link = uri.to_s
      channel.description = Sanitize.clean(Server.site['site_description'])
      channel.author = Server.site['site_contact_username']
      channel.date = Time.now
      channel.generator = Package.user_agent
    end

    def root_url
      return (@config['local']['root_url'] || "https://#{Socket.gethostname}")
    end

    def tz
      return Time.now.strftime('%:z') unless @config['local']['tz_offset']
      return '%+02d:00' % @config['local']['tz_offset'].to_i
    end
  end
end