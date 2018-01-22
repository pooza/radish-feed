require 'active_support'
require 'active_support/core_ext'
require 'syslog/logger'
require 'radish-feed/config'
require 'radish-feed/postgres'
require 'radish-feed/atom'
require 'radish-feed/xml'

module RadishFeed
  class Application < Sinatra::Base
    def initialize
      super
      @config = Config.new
      @logger = Syslog::Logger.new(@config['application']['name'])
      @logger.info({
        message: 'starting...',
        package: {
          name: @config['application']['name'],
          version: @config['application']['version'],
        },
        server: {
          port: @config['thin']['port'],
        },
      }.to_json)
      @db = Postgres.new
    end

    before do
      @message = {request:{path: request.path, params:params}, response:{}}
      @status = 200
      @type = 'application/atom+xml; charset=UTF-8'
    end

    after do
      @message[:response][:status] ||= @status
      if (@status < 300)
        @logger.info(@message.to_json)
      else
        @logger.error(@message.to_json)
      end
      status @status
      content_type @type
    end

    get '/about' do
      @message[:response][:status] = @status
      @message[:response][:message] = '%s %s'%([
        @config['application']['name'],
        @config['application']['version'],
      ])
      xml = XML.new
      @type = xml.type
      return xml.generate(@message).to_s
    end

    get '/feed/v1.1/account/:account' do
      unless registered?(params[:account])
        @status = 404
        @message[:response][:status] = @status
        @message[:response][:message] = "Account #{params[:account]} not found."
        xml = XML.new
        @type = xml.type
        return xml.generate(@message).to_s
      end
      atom = Atom.new(@db)
      atom.tweetable = (params[:tweetable] || true)
      atom.title_length = params[:length]
      @type = atom.type
      return atom.generate(
        'account_timeline',
        [params[:account], params[:entries].to_i]
      ).to_s
    end

    get '/feed/v1.1/local' do
      atom = Atom.new(@db)
      atom.tweetable = (params[:tweetable] || false)
      atom.title_length = params[:length]
      @type = atom.type
      return atom.generate(
        'local_timeline',
        [params[:entries].to_i]
      ).to_s
    end

    not_found do
      @status = 404
      @message[:response][:status] = @status
      @message[:response][:message] = "Resource #{@message[:request][:path]} not found."
      xml = XML.new
      @type = xml.type
      return xml.generate(@message).to_s
    end

    error do
      @status = 500
      @message[:response][:status] = @status
      @message[:response][:message] = env['sinatra.error'].message
      xml = XML.new
      @type = xml.type
      return xml.generate(@message).to_s
    end

    private
    def registered? (account)
      return !@db.execute('registered', [account]).empty?
    end
  end
end
