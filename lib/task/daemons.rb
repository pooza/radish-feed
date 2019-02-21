namespace :radish do
  [:thin].each do |ns|
    namespace ns do
      [:start, :stop].each do |action|
        desc "#{action} #{ns}"
        task action do
          sh "#{File.join(RadishFeed::Environment.dir, 'bin', "#{ns}_daemon.rb")} #{action}"
        rescue => e
          STDERR.puts "#{e.class} #{ns}:#{action} #{e.message}"
        end
      end

      desc "restart #{ns}"
      task restart: [:stop, :start]
    end
  end
end
