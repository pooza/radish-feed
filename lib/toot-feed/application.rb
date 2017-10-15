require 'yaml'
require 'syslog/logger'

module TootFeed
  class Application < Sinatra::Base
    def initialize
      super
      @config = YAML.load_file(File.join(ROOT_DIR, 'config/toot-feed.yaml'))
      @config['thin'] = YAML.load_file(File.join(ROOT_DIR, 'config/thin.yaml'))
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
      })
    end

    before do
      @message = {request:{path: request.path}, response:{}}
      @status = 200
    end

    after do
      @message[:response][:status] = @status
      if (@status < 300)
        @logger.info(@message.to_json)
      else
        @logger.error(@message.to_json)
      end
      status @status
    end

    get '/feed/:account' do
      content_type 'application/atom+xml'
      return '<xml>' + params[:account] + '</xml>'
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
  end
end
