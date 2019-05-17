module RadishFeed
  module Package
    def module_name
      return 'RadishFeed'
    end

    def environment_class
      return "#{module_name}::Environment".constantize
    end

    def package_class
      return "#{module_name}::Package".constantize
    end

    def config_class
      return "#{module_name}::Config".constantize
    end

    def logger_class
      return "#{module_name}::Logger".constantize
    end

    def database_class
      return "#{module_name}::Postgres".constantize
    end

    def http_class
      return "#{module_name}::HTTP".constantize
    end

    def query_template_class
      return "#{module_name}::QueryTemplate".constantize
    end

    def self.name
      return 'radish-feed'
    end

    def self.version
      return Config.instance['/package/version']
    end

    def self.url
      return Config.instance['/package/url']
    end

    def self.full_name
      return "#{name} #{version}"
    end

    def self.user_agent
      return "#{name}/#{version} (#{url})"
    end
  end
end
