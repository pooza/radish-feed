module RadishFeed
  class ImprementError < StandardError
    def status
      return 500
    end
  end
end
