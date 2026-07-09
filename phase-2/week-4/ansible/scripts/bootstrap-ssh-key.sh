#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
key_path="${root_dir}/.ssh/lab_key"

install -d -m 0700 "${root_dir}/.ssh"

if [[ ! -f "${key_path}" ]]; then
    ssh-keygen -t ed25519 -N "" -f "${key_path}" -C "ansible-nginx-lab"
fi

chmod 0600 "${key_path}"
chmod 0644 "${key_path}.pub"

echo "SSH key ready: ${key_path}"
