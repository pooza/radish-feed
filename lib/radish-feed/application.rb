require 'yaml'
require 'pg'
require 'rss'
require 'rexml/document'
require 'syslog/logger'

module RadishFeed
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
      }.to_json)
    end

    before do
      @message = {request:{path: request.path, params:params}, response:{}}
      @status = 200
      @type = 'application/atom+xml'
    end

    after do
      @message[:response][:status] ||= @status
      if (@status < 300)
        logger.info(@message.to_json)
      else
        logger.error(@message.to_json)
      end
      status @status
      content_type @type
    end

    get '/about' do
      @message[:response][:status] = @status
      @message[:response][:message] = '%s %s'%([
        config['application']['name'],
        config['application']['version'],
      ])
      @type = 'application/xml'
      return result_xml(@message).to_s
    end

    get '/feed/:account' do
      unless registered?(params[:account])
        @status = 404
        @message[:response][:status] = @status
        @message[:response][:message] = "Account #{params[:account]} not found."
        @type = 'application/xml'
        return result_xml(@message).to_s
      end
      return atom_feed(params[:account], params[:entries].to_i).to_s
    end

    not_found do
      @status = 404
      @message[:response][:status] = @status
      @message[:response][:message] = "Resource #{@message[:request][:path]} not found."
      @type = 'application/xml'
      return result_xml(@message).to_s
    end

    error do
      @status = 500
      @message[:response][:status] = @status
      @message[:response][:message] = env['sinatra.error'].message
      @type = 'application/xml'
      return result_xml(@message).to_s
    end

    private
    def config
      unless @config
        @config = {}
        Dir.glob(File.join(ROOT_DIR, 'config', '*.yaml')).each do |f|
          @config[File.basename(f, '.yaml')] = YAML.load_file(f)
        end
        @config['db'] ||= {
          'host' => 'localhost',
          'user' => 'postgres',
          'password' => '',
          'dbname' =>'mastodon',
          'port' => 5432,
        }
        @config['local'] ||= {}
        @config['local']['entries'] ||= {'default' => 50, 'max' => 200}
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
    end

    def logger
      unless @logger
        @logger = Syslog::Logger.new(config['application']['name'])
      end
      return @logger
    end

    def result_xml (result)
      xml = REXML::Document.new
      xml.add(REXML::XMLDecl.new('1.0', 'UTF-8'))
      xml.add_element(REXML::Element.new('result'))
      status = xml.root.add_element('status')
      status.add_text(result[:response][:status].to_s)
      message = xml.root.add_element('message')
      message.add_text(result[:response][:message] || 'error')
      return xml
    end

    def atom_feed (account, entries)
      return RSS::Maker.make('atom') do |maker|
        maker.channel.id = config['local']['root_url']
        maker.channel.title = site['site_title']
        maker.channel.description = site['site_description']
        maker.channel.link = config['local']['root_url']
        maker.channel.author = site['site_contact_username']
        maker.channel.date = Time.now
        maker.items.do_sort = true

        entries = config['local']['entries']['default'] if entries.zero?
        if config['local']['entries']['max'] < entries
          entries = config['local']['entries']['max']
        end
        @message[:response][:entries] = entries

        db.exec(config['query']['toots'], [account, entries]).each do |row|
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
