class Current < ActiveSupport::CurrentAttributes
  AUDIT_LOGGER_NAME = "RemoteConnection::Audit".freeze

  # リクエスト由来の監査コンテキスト(ApplicationControllerで設定)
  attribute :request_id, :remote_ip, :user_agent

  class << self
    delegate :logger, :audit, to: :instance
  end

  # 接続の監査ログ用Semantic Logger
  def logger
    SemanticLogger[AUDIT_LOGGER_NAME]
  end

  # 監査ログを構造化ペイロードとして出力する。パスワード等の秘匿情報は渡さないこと。
  def audit(event, level: :info, **fields)
    logger.public_send(level, message: event, payload: {
      client_ip: remote_ip, request_id:, user_agent:, **fields
    })
  end
end
