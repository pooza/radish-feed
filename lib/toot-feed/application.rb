require 'yaml'
require 'rmagick'
require 'sinatra/json'
require 'digest/sha1'
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
      @type = :json
    end

    after do
      @message[:request][:params] = params.to_h
      @message[:response][:status] = @status
      @message[:response][:type] = @type
      if (@status < 300)
        @logger.info(json(@message))
      else
        @logger.error(json(@message))
      end
      content_type @type
      status @status
    end

    post '/feed' do

    end

    not_found do
      @status = 404
      return json(@message)
    end

    error do
      @status = 500
      return json(@message)
    end
  end
end
