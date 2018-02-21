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
      @config = Config.instance
      Application.logger.info({
        message: 'starting...',
        package: {
          name: Application.name,
          version: Application.version,
        },
        server: {
          port: @config['thin']['port'],
        },
      }.to_json)
    end

    before do
      @message = {request:{path: request.path, params:params}, response:{}}
      @renderer = XML.new
    end

    after do
      @message[:response][:status] ||= @renderer.status
      if (@renderer.status < 300)
        Application.logger.info(@message.to_json)
      else
        Application.logger.error(@message.to_json)
      end
      status @renderer.status
      content_type @renderer.type
    end

    get '/about' do
      @message[:response][:status] = @renderer.status
      @message[:response][:message] = Application.full_name
      @renderer.message = @message
      return @renderer.to_s
    end

    get '/feed/v1.1/account/:account' do
      unless registered?(params[:account])
        @renderer.status = 404
        @message[:response][:status] = @renderer.status
        @message[:response][:message] = "Account #{params[:account]} not found."
        @renderer.message = @message
        return @renderer.to_s
      end
      @renderer = Atom.new
      @renderer.tweetable = true
      @renderer.tweetable = params[:tweetable]
      @renderer.title_length = params[:length]
      @renderer.query = 'account_timeline'
      @renderer.params = [params[:account], params[:entries].to_i]
      return @renderer.to_s
    end

    get '/feed/v1.1/local' do
      @renderer = Atom.new
      @renderer.tweetable = params[:tweetable]
      @renderer.title_length = params[:length]
      @renderer.query = 'local_timeline'
      @renderer.params = [params[:entries].to_i]
      return @renderer.to_s
    end

    not_found do
      @renderer = XML.new
      @renderer.status = 404
      @message[:response][:status] = @renderer.status
      @message[:response][:message] = "Resource #{@message[:request][:path]} not found."
      @renderer.message = @message
      return @renderer.to_s
    end

    error do
      @renderer = XML.new
      @renderer.status = 500
      @message[:response][:status] = @renderer.status
      @message[:response][:message] = env['sinatra.error'].message
      @renderer.message = @message
      return @renderer.to_s
    end

    def self.name
      return Config.instance['application']['name']
    end

    def self.version
      return Config.instance['application']['version']
    end

    def self.url
      return Config.instance['application']['url']
    end

    def self.full_name
      return "#{Application.name} #{Application.version}"
    end

    def self.logger
      return Syslog::Logger.new(Application.name)
    end

    private
    def registered? (account)
      return !Postgres.instance.execute('registered', [account]).empty?
    end
  end
end
