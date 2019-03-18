module RadishFeed
  module Package
    def environment_class
      return 'RadishFeed::Environment'
    end

    def package_class
      return 'RadishFeed::Package'
    end

    def config_class
      return 'RadishFeed::Config'
    end

    def logger_class
      return 'RadishFeed::Logger'
    end

    def database_class
      return 'RadishFeed::Postgres'
    end

    def query_template_class
      return 'RadishFeed::QueryTemplate'
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
