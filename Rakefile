dir = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(dir, 'app/lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

require 'bundler/setup'
require 'radish_feed'

[:start, :stop, :restart].each do |action|
  desc "alias of radish:thin:#{action}"
  task action => "radish:thin:#{action}"
end

[:build, :clean].each do |action|
  desc "alias of radish:builder:#{action}"
  task action => "radish:builder:#{action}"
end

Dir.glob(File.join(RadishFeed::Environment.dir, 'app/task/*.rb')).sort.each do |f|
  require f
end
