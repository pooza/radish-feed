module RadishFeed
  class NotFoundError < Error
    def status
      return 404
    end
  end
end
