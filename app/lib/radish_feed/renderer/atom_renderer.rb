require 'rss'
require 'digest/sha1'

module RadishFeed
  class ATOMRenderer < Ginseng::Web::Renderer
    include Package

    attr_accessor :query, :params

    def initialize
      super
      @params = {}
    end

    def type
      return 'application/atom+xml; charset=UTF-8'
    end

    def to_s
      cache unless File.exist?(path)
      cache if File.mtime(path) < @config['/feed/minutes'].minutes.ago
      return File.read(path)
    end

    def cache
      File.write(path, feed.to_s)
      @logger.info(action: 'cached', query: @query, params: @params)
    end

    def path
      return File.join(
        Environment.dir,
        'tmp/feed/',
        "#{Digest::SHA1.hexdigest({query: @query, params: @params}.to_json)}.atom",
      )
    end

    def self.build
      config = Config.instance
      logger = Logger.new
      config['/tag/cacheable'].each do |tag|
        renderer = ATOMRenderer.new
        renderer.query = 'tag_timeline'
        renderer.params = {tag: tag, entries: config['/entries/max']}
        renderer.cache
      rescue => e
        logger.error(Ginseng::Error.create(e).to_h.merge(tag: @tag))
      end
    end

    private

    def feed
      return RSS::Maker.make('atom') do |maker|
        update_channel(maker.channel)
        maker.items.do_sort = true
        values = @params.clone
        Postgres.instance.execute(@query, values).each do |row|
          maker.items.new_item do |item|
            item.link = create_link(row[:uri]).to_s
            item.title = create_title(row)
            item.date = Time.parse("#{row[:created_at]} UTC").getlocal(Environment.tz)
          end
        end
      end
    rescue => e
      Logger.new.error(e)
      Slack.broadcast(e)
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
      channel.title = site['site_title']
      channel.id = uri.to_s
      channel.link = uri.to_s
      channel.description = site['site_description'].sanitize
      channel.author = site['site_contact_username']
      channel.date = Time.now
      channel.generator = Package.user_agent
    end

    def site
      @site ||= Postgres.instance.execute('site').map do |row|
        [row[:var], YAML.safe_load(row[:value])]
      end.to_h
      return @site
    end

    def root_url
      return (@config['/root_url'] || "https://#{Environment.hostname}")
    end
  end
end
