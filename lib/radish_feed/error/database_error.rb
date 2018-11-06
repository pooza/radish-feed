module RadishFeed
  class DatabaseError < StandardError
    def status
      return 500
    end
  end
end
