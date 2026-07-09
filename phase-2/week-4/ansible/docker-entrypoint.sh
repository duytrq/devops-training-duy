#!/usr/bin/env bash
set -euo pipefail

install -d -m 0700 -o ansible -g ansible /home/ansible/.ssh

if [[ ! -s /run/ansible-keys/lab_key.pub ]]; then
    echo "Missing /run/ansible-keys/lab_key.pub. Run scripts/bootstrap-ssh-key.sh first." >&2
    exit 1
fi

install -m 0600 -o ansible -g ansible /run/ansible-keys/lab_key.pub /home/ansible/.ssh/authorized_keys

exec /usr/sbin/sshd -D -e
