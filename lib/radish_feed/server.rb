module RadishFeed
  class Server < Ginseng::Web::Sinatra
    include Package

    get '/feed/v1.1/local' do
      @renderer = ATOMRenderer.new
      @renderer.query = 'local_timeline'
      @renderer.params = {entries: @config['/entries/max']}
      return @renderer.to_s
    end

    get '/feed/v1.0/tag/:tag' do
      @renderer = ATOMRenderer.new
      @renderer.query = 'tag_timeline'
      @renderer.params = {tag: params[:tag], entries: @config['/entries/max']}
      return @renderer.to_s
    end

    def default_renderer_class
      return 'Ginseng::Web::XMLRenderer'.constantize
    end
  end
end
