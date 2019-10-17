require 'bootsnap'

Bootsnap.setup(
  cache_dir: File.join(File.expand_path('..', __dir__), 'tmp/cache'),
  load_path_cache: true,
  autoload_paths_cache: true,
  compile_cache_iseq: true,
  compile_cache_yaml: true,
)

require 'active_support'
require 'active_support/core_ext'
require 'active_support/dependencies/autoload'
require 'ginseng'
require 'ginseng/postgres'
require 'ginseng/web'

ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'ATOM'
end

module RadishFeed
  extend ActiveSupport::Autoload

  autoload :Config
  autoload :Environment
  autoload :Logger
  autoload :HTTP
  autoload :Package
  autoload :Postgres
  autoload :QueryTemplate
  autoload :Server
  autoload :Slack
  autoload :Template

  autoload_under 'daemon' do
    autoload :ThinDaemon
  end

  autoload_under 'renderer' do
    autoload :ATOMRenderer
  end
end
