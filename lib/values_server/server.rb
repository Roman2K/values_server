require 'socket'
require 'fileutils'
require 'thread'

module ValuesServer
  ##
  # Example server:
  #
  #   ValuesServer::Server.new '/tmp/tmux_status.sock',
  #     'time'  => lambda { `date` },
  #     'cpu'   => ValuesServer::Cache.new(5).value { TmuxStatus.cpu }.method(:get)
  #
  # Example client:
  #
  #   $ echo cpu | socat UNIX:/tmp/tmux_status.sock -
  #
  class Server
    def initialize(socket_path, values_map, acceptors: 1, handlers: 8)
      @values_map = values_map

      # TODO one thread for acceptor + handler?
      # TODO single (main) thread?
      @acceptors = ThreadPool.new(acceptors)

      # TODO move socket-related code (accept, pooling, transport protocol) to
      # another more abstract project
      @handlers = ThreadPool.new(handlers)
      @server = UNIXServer.new(socket_path)

      puts "Listening at #{@server.path}"

      acceptor = lambda { Utils::Failsafe.new.execute { accept_connections } }
      @acceptors.size.times { @acceptors.execute(&acceptor) }
    end

    def join
      @acceptors.join
      @handlers.join
    ensure
      unless @server.closed?
        path = @server.path
        @server.close
        FileUtils.rm(path) if File.socket? path
      end
    end

  private

    def accept_connections
      loop do
        begin
          socket = @server.accept
        rescue Errno::EBADF
          return
        end
        @handlers.execute(socket) do |sock|
          begin
            key = sock.gets.chomp
            if value = @values_map[key]
              sock.write(value.call.to_s)
            end
          ensure
            sock.close unless sock.closed?
          end
        end
      end
    end

    module Utils
      class Failsafe
        def initialize(success_period: 3600)
          @success_period = success_period
          reset_backoff
        end

        def execute
          yield
        rescue Exception
          $stderr.puts ValuesServer.format_exc($!)
          if @time < Time.now - @success_period
            reset_backoff
          end
          @backoff.attempts += 1
          sleep @backoff.time
          retry
        end

      private

        def reset_backoff
          @backoff = ExponentialBackoff.new
          @time = Time.now
        end
      end

      class ExponentialBackoff
        def initialize
          @attempts = 0
        end

        attr_reader :attempts

        def attempts=(n)
          @attempts = n.to_i
        end

        def time
          @attempts > 0 or return 0.0
          rand * (2 ** (@attempts - 1))
        end
      end
    end
  end
end
