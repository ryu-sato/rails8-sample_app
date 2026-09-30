#!/bin/sh
set -e

# telnetd(busybox)をバックグラウンドで、sshdをフォアグラウンドで起動する
busybox telnetd -l /bin/login
exec /usr/sbin/sshd -D -e
