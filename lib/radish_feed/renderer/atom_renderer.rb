require 'rss'
require 'sanitize'
require 'digest/sha1'

module RadishFeed
  class ATOMRenderer < Ginseng::Web::Renderer
    include Package

    attr_accessor :query
    attr_reader :params

    def initialize
      super
      @params = {}
    end

    def type
      return 'application/atom+xml; charset=UTF-8'
    end

    attr_writer :params

    def to_s
      return feed.to_s
    end

    def cache
      pp path
    end

    def path
      return File.join(
        Environment.dir,
        'tmp/feed/',
        Digest::SHA1.hexdigest({query: @query, params: @params}.to_json),
      )
    end

    def self.build_cache
      config = Config.instance
      renderer = ATOMRenderer.new
      renderer.query = 'local_timeline'
      renderer.params = {entries: config['/entries/max']}
      renderer.cache
      config['/tag/cacheable'].each do |tag|
        renderer = ATOMRenderer.new
        renderer.query = 'tag_timeline'
        renderer.params = {tag: tag, entries: config['/entries/max']}
        renderer.cache
      end
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
        db.execute(@query, values).each do |row|
          maker.items.new_item do |item|
            item.link = create_link(row['uri']).to_s
            item.title = create_title(row)
            item.date = Time.parse("#{row['created_at']} UTC").getlocal(Environment.tz)
          end
        end
      end
    end

    def create_title(row)
      template = Template.new('timeline_entry')
      template[:row] = row
      return template.to_s.chomp
    end

    def create_link(src)
      dest = Ginseng::URI.parse(src)
      return src unless dest.absolute?
      return src unless matches = %r{/users/([[:word:]]+)/statuses/([[:digit:]]+)}i.match(dest.path)
      dest.path = "/@#{matches[1]}/#{matches[2]}"
      return dest.to_s
    end

    def update_channel(channel)
      uri = Ginseng::URI.parse(root_url)
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
      return (@config['/root_url'] || "https://#{Environment.hostname}")
    end
  end
end
