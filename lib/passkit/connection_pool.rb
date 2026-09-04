require_relative "client"

module PassKit
  class ConnectionPool
    def initialize(config, size: config.pool_size)
      raise ArgumentError, "pool size must be at least 1" if size < 1

      @clients = Array.new(size) { Client.new(config) }
      @mutex = Mutex.new
      @index = 0
    end

    def with
      client = @mutex.synchronize do
        selected = @clients[@index]
        @index = (@index + 1) % @clients.length
        selected
      end
      yield client
    end
  end
end
