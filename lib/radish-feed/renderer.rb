module RadishFeed
  class Renderer
    attr :status, true

    def initialize
      @status = 200
    end

    def type
      return 'application/xml; charset=UTF-8'
    end
  end
end
