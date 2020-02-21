namespace :radish do
  namespace :builder do
    desc 'build caches'
    task :build do
      system(File.join(RadishFeed::Environment.dir, 'bin/build.rb'))
    end

    desc 'clean caches'
    task :clean do
      Dir.glob(File.join(RadishFeed::Environment.dir, 'tmp/feed/*')).each do |f|
        File.unlink(f)
      end
    end
  end
end

[:build, :clean].each do |action|
  desc "alias of radish:builder:#{action}"
  task action => "radish:builder:#{action}"
end
