# Ansible Role Nginx Plan

## Goal
Build an Ansible lab that provisions Nginx on two SSH-managed Docker containers, renders Nginx configuration from a template, creates a self-signed TLS certificate, and remains idempotent after convergence.

The target verification command is:

```bash
ansible-playbook -i inventory site.yml --check
```

After the playbook has been applied once, check mode should complete without changes.

## Project Layout
```text
.
├── ansible.cfg
├── docker-compose.yml
├── Dockerfile
├── docker-entrypoint.sh
├── inventory
├── site.yml
├── scripts/
│   └── bootstrap-ssh-key.sh
└── roles/
    └── nginx/
        ├── defaults/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        ├── tasks/
        │   └── main.yml
        └── templates/
            └── nginx.conf.j2
```

## Implementation
- `docker-compose.yml` defines `nginx-host-1` and `nginx-host-2` as local SSH targets.
- `scripts/bootstrap-ssh-key.sh` creates `.ssh/lab_key` and `.ssh/lab_key.pub` for the lab. These files are ignored by git.
- `inventory` maps both containers to localhost SSH ports `2222` and `2223`.
- `site.yml` applies the `nginx` role to the `web` group with privilege escalation.
- The `nginx` role installs `nginx` and `openssl`, creates `/etc/nginx/ssl`, generates a self-signed certificate, renders `/etc/nginx/nginx.conf`, and starts/enables Nginx.
- The Nginx template serves plain text over HTTP and HTTPS, including the target `inventory_hostname` in the response.

## Test Flow
```bash
./scripts/bootstrap-ssh-key.sh
docker compose up -d --build
ansible -i inventory web -m ping
ansible-playbook -i inventory site.yml
ansible-playbook -i inventory site.yml
ansible-playbook -i inventory site.yml --check
curl http://127.0.0.1:8081
curl http://127.0.0.1:8082
curl -k https://127.0.0.1:8441
curl -k https://127.0.0.1:8442
```

Expected result after convergence:
- Re-running `ansible-playbook -i inventory site.yml` reports `changed=0`.
- Running `ansible-playbook -i inventory site.yml --check` reports `changed=0`.
- HTTP and HTTPS endpoints return host-specific text responses.

## Assumptions
- The Docker hosts are local lab targets, so the certificate is self-signed instead of Let's Encrypt.
- Check-mode idempotency is evaluated after the first successful converge.
- The managed containers use Ubuntu 24.04 and the role uses `apt`.
