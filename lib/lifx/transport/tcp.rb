require 'socket'

module LIFX
  class Transport
    # @api private
    # @private
    class TCP < Transport
      include Logging

      def initialize(*args)
        super
        connect
      end

      def connected?
        @socket && !@socket.closed?
      end

      CONNECT_TIMEOUT = 3
      def connect
        Timeout.timeout(CONNECT_TIMEOUT) do
          @socket = TCPSocket.new(host, port) # Performs the connection
        end
        @socket.setsockopt(Socket::SOL_SOCKET,  Socket::SO_SNDBUF,    1024)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY,  1)
        logger.info("#{self}: Connected.")
      rescue => ex
        logger.warn("#{self}: Exception occured in #connect - #{ex}")
        logger.debug("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        @socket = nil
      end

      def close
        return if !@socket
        Thread.kill(@listener) if @listener
        @listener = nil
        @socket.close if !@socket.closed?
        @socket = nil
      end

      HEADER_SIZE = 8
      def listen
        return if @listener
        @listener = Thread.new do
          while @socket do
            begin
              header_data = @socket.recv(HEADER_SIZE, Socket::MSG_PEEK)
              header      = Protocol::Header.read(header_data)
              size        = header.msg_size
              data        = @socket.recv(size)
              message     = Message.unpack(data)
              
              notify_observers(message: message, ip: host, transport: self)
            rescue Message::UnpackError
              if !@ignore_unpackable_messages
                logger.warn("#{self}: Exception occured - #{ex}")
              end
            rescue => ex
              logger.warn("#{self}: Exception occured in #listen - #{ex}")
              logger.debug("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
              close
            end
          end
        end
      end

      SEND_TIMEOUT = 2
      def write(message)
        data = message.pack
        Timeout.timeout(SEND_TIMEOUT) do
          @socket.write(data)
        end
        true
      rescue => ex
        logger.warn("#{self}: Exception in #write: #{ex}")
        logger.debug("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        close
        false
      end
    end
  end
end
