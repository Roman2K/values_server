require 'thread'

module ValuesServer
  class ThreadPool
    def initialize(size)
      @size = size
      @queue = Thread::Queue.new
      @group = ThreadGroup.new
    end

    attr_reader :size

    def execute(*args, &block)
      @queue << lambda { block.call(*args) }
      (@size - @group.list.size).times { spawn }
      self
    end

    def join
      @size.times { @queue << nil }
      while thr = @group.list.first
        thr.join
      end
      @queue.clear
      self
    end
    
  private

    def spawn
      thr = Thread.new { thread_loop }
      @group.add(thr)
    end

    def thread_loop
      while block = @queue.shift
        block.call
      end
    rescue Exception
      # TODO exception handler as a configurable callback
      $stderr.puts ValuesServer.format_exc($!)
      raise
    end
  end
end
