dir = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(dir, 'lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

require 'bundler/setup'
require 'radish_feed'

[:start, :stop, :restart].each do |action|
  desc "#{action} all"
  task action => "radish:thin:#{action}"
end

Dir.glob(File.join(RadishFeed::Environment.dir, 'lib/task/*.rb')).each do |f|
  require f
end
