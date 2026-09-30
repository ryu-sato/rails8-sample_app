require "socket"

module RemoteConnection
  # 最小限のtelnetクライアント。IACネゴシエーションは全て拒否し、
  # login/Password/プロンプトを待ち受けてコマンドを1つ実行する。
  class Telnet
    IAC = 255
    DONT = 254
    DO = 253
    WONT = 252
    WILL = 251
    SB = 250
    SE = 240

    PROMPT = /[$#] \z/

    def initialize(host:, port:, username:, password:)
      @host, @port, @username, @password = host, port, username, password
    end

    def execute(command)
      @socket = Socket.tcp(@host, @port, connect_timeout: TIMEOUT)
      wait_for(/login: ?\z/i)
      send_line(@username)
      wait_for(/password: ?\z/i)
      send_line(@password)
      wait_for(PROMPT, failure: /login incorrect/i)

      send_line(command)
      output = wait_for(PROMPT)
      send_line("exit")
      # エコーされたコマンド行と末尾のプロンプトを除去する
      output.lines.drop(1).join.sub(/[^\n]*[$#] \z/, "")
    rescue SystemCallError, SocketError, IOError => e
      raise Error, "Telnet接続に失敗しました: #{e.message}"
    ensure
      @socket&.close
    end

    private
      def send_line(line)
        @socket.write("#{line}\r\n")
      end

      # patternに一致するまで読み込み、それまでの文字列を返す
      def wait_for(pattern, failure: nil)
        buffer = +""
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TIMEOUT
        loop do
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise Error, "Telnetがタイムアウトしました" if remaining <= 0 || @socket.wait_readable(remaining).nil?

          chunk = @socket.read_nonblock(4096, exception: false)
          next if chunk == :wait_readable
          raise Error, "Telnet接続が切断されました" if chunk.nil?

          buffer << strip_negotiation(chunk)
          raise Error, "Telnetログインに失敗しました" if failure && buffer.match?(failure)
          return buffer.delete("\r") if buffer.match?(pattern)
        end
      end

      # IACコマンドに応答して除去する(全オプションを拒否)
      def strip_negotiation(data)
        bytes = data.bytes
        text = []
        i = 0
        while i < bytes.size
          if bytes[i] == IAC
            cmd = bytes[i + 1]
            case cmd
            when DO, DONT
              @socket.write([ IAC, WONT, bytes[i + 2] ].pack("C*"))
              i += 3
            when WILL, WONT
              @socket.write([ IAC, DONT, bytes[i + 2] ].pack("C*"))
              i += 3
            when SB
              i += 2
              i += 1 until i >= bytes.size || (bytes[i] == IAC && bytes[i + 1] == SE)
              i += 2
            when IAC
              text << IAC
              i += 2
            else
              i += 2
            end
          else
            text << bytes[i]
            i += 1
          end
        end
        text.pack("C*").force_encoding(Encoding::UTF_8).scrub
      end
  end
end
