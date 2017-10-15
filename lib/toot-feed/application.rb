require 'yaml'
require 'pg'
require 'rss'
require 'syslog/logger'

module TootFeed
  class Application < Sinatra::Base
    def initialize
      super
      logger.info({
        message: 'starting...',
        package: {
          name: config['application']['name'],
          version: config['application']['version'],
        },
        server: {
          port: config['thin']['port'],
        },
      })
    end

    before do
      @message = {request:{path: request.path}, response:{}}
      @status = 200
    end

    after do
      @message[:response][:status] = @status
      if (@status < 300)
        logger.info(@message.to_json)
      else
        logger.error(@message.to_json)
      end
      status @status
    end

    get '/feed/:account' do
      unless registered?(params[:account])
        @status = 404
        content_type 'application/json'
        return @message.to_json
      end
      content_type 'application/atom+xml'
      return atom(params[:account]).to_s
    end

    not_found do
      @status = 404
      content_type 'application/json'
      return @message.to_json
    end

    error do
      @status = 500
      content_type 'application/json'
      return @message.to_json
    end

    private
    def config
      unless @config
        @config = YAML.load_file(File.join(ROOT_DIR, 'config/toot-feed.yaml'))
        ['thin', 'query', 'local'].each do |key|
          @config[key] = YAML.load_file(File.join(ROOT_DIR, 'config', "#{key}.yaml"))
        end
        if File.exist?(File.join(ROOT_DIR, 'config/db.yaml'))
          @config['db'] = YAML.load_file(File.join(ROOT_DIR, 'config/db.yaml'))
        else
          @config['db'] = {
            'host' => 'localhost',
            'user' => 'postgres',
            'password' => '',
            'dbname' =>'mastodon',
            'port' => 5432,
          }
        end
      end
      return @config
    end

    def db
      unless @db
        @db = PG::connect({
          host: config['db']['host'],
          user: config['db']['user'],
          password: config['db']['password'],
          dbname: config['db']['dbname'],
          port: config['db']['port'],
        })
      end
      return @db
    rescue => e
      @message[:error] = e.message
      raise e.message
    end

    def logger
      unless @logger
        @logger = Syslog::Logger.new(config['application']['name'])
      end
      return @logger
    end

    def atom (account)
      return RSS::Maker.make('atom') do |maker|
        maker.channel.id = config['local']['root_url']
        maker.channel.title = site['site_title']
        maker.channel.description = site['site_description']
        maker.channel.link = config['local']['root_url']
        maker.channel.author = site['site_contact_username']
        maker.channel.date = Time.now
        maker.items.do_sort = true

        db.exec(config['query']['toots'], [account]).each do |row|
          maker.items.new_item do |item|
            item.link = row['uri']
            item.title = row['text']
            item.date = Time.parse(row['created_at']) + ((config['local']['tz_offset'] || 0) * 3600)
          end
        end
      end
    end

    def registered? (account)
      return !db.exec(config['query']['registered'], [account]).to_a.empty?
    end

    def site
      unless @site
        @site = {}
        db.exec(config['query']['site']).each do |row|
          @site[row['var']] = YAML.load(row['value'])
        end
      end
      return @site
    end
  end
end
