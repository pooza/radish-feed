require 'active_support'
require 'active_support/core_ext'
require 'active_support/dependencies/autoload'
require 'ginseng'
require 'ginseng/postgres'

ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'ATOM'
end

module RadishFeed
  extend ActiveSupport::Autoload

  autoload :Config
  autoload :Environment
  autoload :Logger
  autoload :Package
  autoload :Postgres
  autoload :Server
  autoload :Slack
  autoload :TweetString

  autoload_under 'daemon' do
    autoload :ThinDaemon
  end

  autoload_under 'renderer' do
    autoload :ATOMRenderer
  end
end
