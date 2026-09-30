# リモートホストへコマンドを実行する接続クライアントの共通部分。
# 接続先は REMOTE_ALLOWED_HOSTS(カンマ区切り, 既定: target-host)に限定する(SSRF対策)。
module RemoteConnection
  class Error < StandardError; end

  PROTOCOLS = {
    "ssh" => { klass: "RemoteConnection::Ssh", default_port: 22 },
    "telnet" => { klass: "RemoteConnection::Telnet", default_port: 23 }
  }.freeze

  TIMEOUT = 10

  def self.allowed_hosts
    ENV.fetch("REMOTE_ALLOWED_HOSTS", "target-host").split(",").map(&:strip)
  end

  def self.execute(protocol:, host:, port:, username:, password:, command:)
    config = PROTOCOLS[protocol] or raise Error, "未対応のプロトコルです: #{protocol}"
    raise Error, "許可されていないホストです: #{host}" unless allowed_hosts.include?(host)

    port = port.presence&.to_i || config[:default_port]
    config[:klass].constantize.new(host:, port:, username:, password:).execute(command)
  end
end
