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
    target = { protocol:, host:, port: port.presence, username:, command: }
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Current.audit("remote_connection.attempt", **target)

    config = PROTOCOLS[protocol] or raise Error, "未対応のプロトコルです: #{protocol}"
    raise Error, "許可されていないホストです: #{host}" unless allowed_hosts.include?(host)

    port = port.presence&.to_i || config[:default_port]
    target[:port] = port
    output = config[:klass].constantize.new(host:, port:, username:, password:).execute(command)
    Current.audit("remote_connection.success", **target, outcome: "success",
                  duration_ms: elapsed_ms(started), output_bytes: output.bytesize)
    output
  rescue Error => e
    Current.audit("remote_connection.failure", level: :warn, **target, outcome: "failure",
                  duration_ms: elapsed_ms(started), error: e.message)
    raise
  end

  def self.elapsed_ms(started)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
  end
  private_class_method :elapsed_ms
end
