dir = File.expand_path(__dir__)
$LOAD_PATH.push(File.join(dir, 'lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')
ENV['SSL_CERT_FILE'] ||= File.join(dir, 'cert/cacert.pem')

require 'bundler/setup'
require 'radish_feed'

desc 'test'
task :test do
  require 'test/unit'
  Dir.glob(File.join(RadishFeed::Environment.dir, 'test/*')).each do |t|
    require t
  end
end

namespace :cert do
  desc 'update cert'
  task :update do
    require 'httparty'
    File.write(
      File.join(RadishFeed::Environment.dir, 'cert/cacert.pem'),
      HTTParty.get('https://curl.haxx.se/ca/cacert.pem'),
    )
  end
end

[:start, :stop, :restart].each do |action|
  desc "alias of server:#{action}"
  task action => ["server:#{action}"]
end

namespace :server do
  [:start, :stop, :restart].each do |action|
    desc "#{action} server"
    task action do
      sh "thin --config config/thin.yaml #{action}"
    end
  end
end
