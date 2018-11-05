require 'active_support'
require 'active_support/core_ext'
require 'active_support/dependencies/autoload'

module RadishFeed
  extend ActiveSupport::Autoload

  autoload :Config
  autoload :Logger
  autoload :Package
  autoload :Postgres
  autoload :Renderer
  autoload :Server
  autoload :Slack
  autoload :TweetString

  autoload_under 'error' do
    autoload :ConfigError
    autoload :ExternalServiceError
    autoload :ImprementError
    autoload :NotFoundError
    autoload :RequestError
  end

  autoload_under 'renderer' do
    autoload :AtomRenderer
    autoload :XmlRenderer
  end
end
