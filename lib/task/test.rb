namespace :radish do
  task :test do
    ENV['TEST'] = RadishFeed::Package.name
    require 'test/unit'
    Dir.glob(File.join(RadishFeed::Environment.dir, 'test/*')).each do |t|
      require t
    end
  end
end
