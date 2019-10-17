namespace :radish do
  namespace :builder do
    desc 'build caches'
    task :build do
      sh File.join(RadishFeed::Environment.dir, 'bin/build.rb')
    end

    desc 'clear caches'
    task :clear do
      Dir.glob(File.join(RadishFeed::Environment.dir, 'tmp/feed/*')).each do |f|
        File.unlink(f)
      end
    end
  end
end
