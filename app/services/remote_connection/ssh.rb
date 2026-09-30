require "net/ssh"

module RemoteConnection
  class Ssh
    def initialize(host:, port:, username:, password:)
      @host, @port, @username, @password = host, port, username, password
    end

    def execute(command)
      Net::SSH.start(@host, @username,
                     port: @port, password: @password, timeout: TIMEOUT,
                     non_interactive: true, verify_host_key: :never,
                     use_agent: false, keys: [], config: false) do |ssh|
        ssh.exec!(command).to_s
      end
    rescue Net::SSH::Exception, SystemCallError, SocketError, Timeout::Error => e
      raise Error, "SSH接続に失敗しました: #{e.message}"
    end
  end
end
