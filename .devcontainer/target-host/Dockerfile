# 接続テスト用ホスト(SSH:22 / Telnet:23)。開発専用。認証情報は固定のため公開しないこと。
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server busybox-static \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd \
    && useradd -m -s /bin/bash testuser \
    && echo "testuser:password" | chpasswd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 23
ENTRYPOINT ["/entrypoint.sh"]
