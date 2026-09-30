require "net/telnet"

module RemoteConnection
  # Net::Telnet(net-telnet gem)を使ったtelnetクライアント。
  # ログイン後にコマンドを1つ実行して結果を返す。
  class Telnet
    PROMPT = /[$#] \z/n

    def initialize(host:, port:, username:, password:)
      @host, @port, @username, @password = host, port, username, password
    end

    def execute(command)
      @telnet = Net::Telnet.new(
        "Host" => @host, "Port" => @port,
        "Timeout" => TIMEOUT, "Prompt" => PROMPT
      )
      @telnet.login("Name" => @username, "Password" => @password)
      output = @telnet.cmd(command)
      @telnet.puts("exit")
      # エコーされたコマンド行と末尾のプロンプトを除去する
      output.to_s.lines.drop(1).join.sub(/[^\n]*[$#] \z/, "")
    rescue Timeout::Error, Net::ReadTimeout, Net::OpenTimeout => e
      raise Error, "Telnetがタイムアウトしました(ログイン失敗の可能性があります): #{e.message}"
    rescue SystemCallError, SocketError, IOError, EOFError => e
      raise Error, "Telnet接続に失敗しました: #{e.message}"
    ensure
      @telnet&.close
    end
  end
end
