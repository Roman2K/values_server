module ValuesServer
  class Cache
    def initialize(ttl)
      @ttl = ttl
    end

    def fetch
      now = Time.now
      @last = nil if @time && @time < now - @ttl
      @last ||= begin
        @time = now
        yield
      end
    end

    def value(&get)
      Value.new(self, get)
    end

    class Value
      def initialize(cache, get)
        @cache = cache
        @get = get
      end
      
      def get
        @cache.fetch { @get.call }
      end
    end
  end
end
