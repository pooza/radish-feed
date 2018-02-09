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
    end

    before do
      @message = {request:{path: request.path, params:params}, response:{}}
      @renderer = XML.new
    end

    after do
      @message[:response][:status] ||= @status
      if (@renderer.status < 300)
        @logger.info(@message.to_json)
      else
        @logger.error(@message.to_json)
      end
      status @renderer.status
      content_type @renderer.type
    end

    get '/about' do
      @message[:response][:status] = @status
      @message[:response][:message] = '%s %s'%([
        @config['application']['name'],
        @config['application']['version'],
      ])
      return @renderer.generate(@message).to_s
    end

    get '/feed/v1.1/account/:account' do
      unless registered?(params[:account])
        @renderer.status = 404
        @message[:response][:status] = @status
        @message[:response][:message] = "Account #{params[:account]} not found."
        return @renderer.generate(@message).to_s
      end
      @renderer = Atom.new
      @renderer.tweetable = true
      @renderer.tweetable = params[:tweetable]
      @renderer.title_length = params[:length]
      return @renderer.generate(
        'account_timeline',
        [params[:account], params[:entries].to_i]
      ).to_s
    end

    get '/feed/v1.1/local' do
      @renderer = Atom.new
      @renderer.tweetable = params[:tweetable]
      @renderer.title_length = params[:length]
      return @renderer.generate(
        'local_timeline',
        [params[:entries].to_i]
      ).to_s
    end

    not_found do
      @renderer.status = 404
      @message[:response][:status] = @status
      @message[:response][:message] = "Resource #{@message[:request][:path]} not found."
      return @renderer.generate(@message).to_s
    end

    error do
      @renderer.status = 500
      @message[:response][:status] = @status
      @message[:response][:message] = env['sinatra.error'].message
      return @renderer.generate(@message).to_s
    end

    private
    def registered? (account)
      return !Postgres.new.execute('registered', [account]).empty?
    end
  end
end