require 'radish-feed/config'

module RadishFeed
  class Renderer
    attr :status, true

    def initialize
      @status = 200
      @config = Config.new
    end

    def type
      return 'application/xml; charset=UTF-8'
    end

    def to_s
      raise 'to_sが未定義です。'
    end
  end
end
