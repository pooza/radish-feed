module RadishFeed
  class Environment < Ginseng::Environment
    def self.name
      return File.basename(dir)
    end

    def self.dir
      return RadishFeed.dir
    end
  end
end
