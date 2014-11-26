require 'socket'
require 'fileutils'

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
  #   $ echo cpu | nc -U /tmp/tmux_status.sock
  #
  class Server
    def initialize(socket_path, values_map)
      @values_map = values_map
      @server = UNIXServer.new(socket_path)
      puts "Listening at #{@server.path}"
      begin
        accept_connections
      ensure
        @server.close unless @server.closed?
        FileUtils.rm(socket_path) if File.socket? socket_path
      end
    end

  private

    def accept_connections
      loop do
        begin
          sock = @server.accept
        rescue Errno::EBADF
          return
        end
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
end
