require 'time'

module RadishFeed
  class Environment < Ginseng::Environment
    def self.name
      return File.basename(dir)
    end

    def self.dir
      return File.expand_path('../..', __dir__)
    end

    def self.tz
      return '%+02d:00' % Config.instance['/tz_offset'].to_i
    rescue Ginseng::ConfigError
      return Time.now.strftime('%:z')
    end
  end
end
