require 'rss'

module RadishFeed
  class Atom
    def initialize (db, config)
      @db = db
      @config = config
    end

    def type
      return 'application/atom+xml'
    end

    def generate (account, entries)
      return RSS::Maker.make('atom') do |maker|
        maker.channel.id = @config['local']['root_url']
        maker.channel.title = site['site_title']
        maker.channel.description = site['site_description']
        maker.channel.link = @config['local']['root_url']
        maker.channel.author = site['site_contact_username']
        maker.channel.date = Time.now
        maker.items.do_sort = true

        entries = @config['local']['entries']['default'] if entries.zero?
        if @config['local']['entries']['max'] < entries
          entries = @config['local']['entries']['max']
        end

        @db.exec(@config['query']['toots'], [account, entries]).each do |row|
          maker.items.new_item do |item|
            item.link = row['uri']
            item.title = row['text']
            item.date = Time.parse(row['created_at']) + ((@config['local']['tz_offset'] || 0) * 3600)
          end
        end
      end
    end

    private
    def site
      unless @site
        @site = {}
        @db.exec(@config['query']['site']).each do |row|
          @site[row['var']] = YAML.load(row['value'])
        end
      end
      return @site
    end
  end
end
