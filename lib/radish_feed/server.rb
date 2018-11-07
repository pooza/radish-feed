require 'sinatra'

module RadishFeed
  class Server < Sinatra::Base
    def initialize
      super
      @config = Config.instance
      @logger = Logger.new
      @logger.info({
        message: 'starting...',
        server: {port: @config['thin']['port']},
        version: Package.version,
      })
    end

    before do
      @message = {request: {path: request.path, params: params}, response: {}}
      @renderer = XmlRenderer.new
    end

    after do
      @message[:response][:status] ||= @renderer.status
      if @renderer.status < 400
        @logger.info(@message)
      else
        @logger.error(@message)
      end
      status @renderer.status
      content_type @renderer.type
    end

    get '/about' do
      Server.site
      @message[:response][:message] = Package.full_name
      @renderer.message = @message
      return @renderer.to_s
    end

    get '/feed/v1.1/account/:account' do
      unless registered?(params[:account])
        raise NotFoundError, "Account #{params[:account]} not found."
      end
      @renderer = AtomRenderer.new
      @renderer.tweetable = true
      @renderer.tweetable = params[:tweetable]
      @renderer.title_length = params[:length]
      @renderer.actor_type = params[:actor_type]
      @renderer.hashtag = params[:hashtag]
      @renderer.ignore_cw = params[:ignore_cw]
      @renderer.attachments = params[:attachments]
      @renderer.visibility = params[:visibility]
      @renderer.query = 'account_timeline'
      @renderer.params = {account: params[:account], entries: params[:entries]}
      return @renderer.to_s
    end

    get '/feed/v1.1/local' do
      @renderer = AtomRenderer.new
      @renderer.tweetable = params[:tweetable]
      @renderer.title_length = params[:length]
      @renderer.actor_type = params[:actor_type]
      @renderer.hashtag = params[:hashtag]
      @renderer.ignore_cw = params[:ignore_cw]
      @renderer.attachments = params[:attachments]
      @renderer.visibility = params[:visibility]
      @renderer.query = 'local_timeline'
      @renderer.params = {entries: params[:entries]}
      return @renderer.to_s
    end

    not_found do
      @renderer = XmlRenderer.new
      @renderer.status = 404
      @message[:response][:message] = "Resource #{@message[:request][:path]} not found."
      @renderer.message = @message
      return @renderer.to_s
    end

    error do |e|
      @renderer = XmlRenderer.new
      begin
        @renderer.status = e.status
      rescue NoMethodError
        @renderer.status = 500
      end
      @message[:response][:message] = "#{e.class}: #{e.message}"
      @message[:backtrace] = e.backtrace[0..5]
      @renderer.message = @message
      Slack.broadcast(@message)
      return @renderer.to_s
    end

    def self.site
      site = {}
      Postgres.instance.execute('site').each do |row|
        site[row['var']] = YAML.safe_load(row['value'])
      end
      return site
    end

    private

    def registered?(account)
      return !Postgres.instance.execute('registered', {account: account}).empty?
    end
  end
end
