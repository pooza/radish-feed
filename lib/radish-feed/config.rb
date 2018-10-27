require 'yaml'
require 'singleton'
require 'radish-feed/package'
require 'radish-feed/error/config'

module RadishFeed
  class Config < ::Hash
    include Singleton

    def initialize
      super
      dirs.each do |dir|
        suffixes.each do |suffix|
          Dir.glob(File.join(dir, "*#{suffix}")).each do |f|
            key = File.basename(f, suffix)
            self[key] = YAML.load_file(f) unless self[key]
          end
        end
      end
      self['db'] ||= {
        'host' => 'localhost',
        'user' => 'postgres',
        'password' => '',
        'dbname' => 'mastodon',
        'port' => 5432,
      }
      self['local'] ||= {}
      self['local']['entries'] ||= {'default' => 50, 'max' => 200}
    end

    def dirs
      return [
        File.join('/usr/local/etc', Package.name),
        File.join('/etc', Package.name),
        File.join(ROOT_DIR, 'config'),
      ]
    end

    def suffixes
      return ['.yaml', '.yml']
    end

    def self.validate(name)
      keys = name.split('/')
      keys.shift
      config = instance
      keys.each do |key|
        config = config[key]
        raise ConfigError, "#{name} が未定義です。" unless config.present?
      end
      return true
    end
  end
end
