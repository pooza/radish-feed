desc 'test all'
task :test do
  ENV['TEST'] = RadishFeed::Package.name
  require 'test/unit'
  Dir.glob(File.join(RadishFeed::Environment.dir, 'test/*.rb')).sort.each do |t|
    require t
  end
end
